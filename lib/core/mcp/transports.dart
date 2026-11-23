import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:rocket_mcp/core/logging/log.dart';

/// Abstract transport for JSON-RPC 2.0 communication with an MCP server.
abstract class McpTransport {
  /// Initiates connection or launches the process.
  Future<void> connect();

  /// Sends an encoded JSON-RPC map to the server.
  Future<void> send(Map<String, dynamic> message);

  /// Stream of incoming JSON-RPC maps from the server.
  Stream<Map<String, dynamic>> get incoming;

  /// Diagnostic/stderr log stream (mainly for stdio processes).
  Stream<String> get stderrLines;

  /// Whether the transport is currently connected and ready.
  bool get isConnected;

  /// Closes the transport and releases underlying resources.
  Future<void> close();
}

/// Standard I/O transport that communicates with a local child process via stdin/stdout.
class McpStdioTransport implements McpTransport {
  McpStdioTransport({
    required this.command,
    this.args = const [],
    this.environment = const {},
    this.workingDirectory,
  });

  static const String _tag = 'stdio_transport';

  final String command;
  final List<String> args;
  final Map<String, String> environment;
  final String? workingDirectory;

  Process? _process;
  final StreamController<Map<String, dynamic>> _incomingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  bool _connected = false;

  @override
  Stream<Map<String, dynamic>> get incoming => _incomingController.stream;

  @override
  Stream<String> get stderrLines => _stderrController.stream;

  @override
  bool get isConnected => _connected && _process != null;

  @override
  Future<void> connect() async {
    if (_connected) return;

    try {
      Log.info(_tag, 'Launching process: $command with ${args.length} args');
      final proc = await Process.start(
        command,
        args,
        environment: environment.isEmpty ? null : environment,
        workingDirectory:
            (workingDirectory != null && workingDirectory!.trim().isNotEmpty)
            ? workingDirectory
            : null,
        runInShell: Platform.isWindows,
      );

      _process = proc;
      _connected = true;

      // Handle standard output (JSON-RPC messages line by line)
      _stdoutSub = proc.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              final trimmed = line.trim();
              if (trimmed.isEmpty) return;
              try {
                final decoded = jsonDecode(trimmed);
                if (decoded is Map<String, dynamic>) {
                  _incomingController.add(decoded);
                } else if (decoded is Map) {
                  _incomingController.add(Map<String, dynamic>.from(decoded));
                }
              } catch (_) {
                // Ignore non-JSON diagnostic lines printed by some servers to stdout
                _stderrController.add('[STDOUT] $trimmed');
              }
            },
            onError: (err, st) {
              Log.error(_tag, 'Error on stdout stream', err, st);
              _stderrController.add('[ERROR] stdout: $err');
            },
            onDone: () {
              Log.info(_tag, 'Process stdout closed');
              _connected = false;
            },
          );

      // Handle standard error (Server logs)
      _stderrSub = proc.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              _stderrController.add(line);
            },
            onError: (err) {
              _stderrController.add('[ERROR] stderr: $err');
            },
          );

      proc.exitCode.then((code) {
        Log.info(_tag, 'Process exited with code $code');
        _connected = false;
        _stderrController.add('[PROCESS EXITED] code $code');
      });
    } catch (e, st) {
      _connected = false;
      Log.error(_tag, 'Failed to launch process: $command', e, st);
      _stderrController.add('[LAUNCH FAILED] $e');
      rethrow;
    }
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    final proc = _process;
    if (proc == null || !_connected) {
      throw StateError('Cannot send message: stdio process is not connected');
    }

    try {
      final line = jsonEncode(message);
      proc.stdin.writeln(line);
      await proc.stdin.flush();
    } catch (e, st) {
      Log.error(_tag, 'Failed to write to stdin', e, st);
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    _connected = false;
    await _stdoutSub?.cancel();
    _stderrSub?.cancel();

    final proc = _process;
    if (proc != null) {
      try {
        proc.kill(ProcessSignal.sigterm);
      } catch (_) {
        proc.kill();
      }
      _process = null;
    }

    if (!_incomingController.isClosed) {
      await _incomingController.close();
    }
    if (!_stderrController.isClosed) {
      await _stderrController.close();
    }
  }
}

/// Server-Sent Events (SSE) transport for remote MCP servers.
class McpSseTransport implements McpTransport {
  McpSseTransport({
    required this.sseUrl,
    this.headers = const {},
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  static const String _tag = 'sse_transport';

  final String sseUrl;
  final Map<String, String> headers;
  final http.Client _client;

  StreamSubscription<String>? _bodySub;
  String? _postEndpoint;

  final StreamController<Map<String, dynamic>> _incomingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();
  bool _connected = false;

  @override
  Stream<Map<String, dynamic>> get incoming => _incomingController.stream;

  @override
  Stream<String> get stderrLines => _stderrController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) return;

    try {
      Log.info(_tag, 'Connecting to SSE endpoint: $sseUrl');
      final uri = Uri.parse(sseUrl);

      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      headers.forEach((k, v) {
        request.headers[k] = v;
      });

      final response = await _client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'SSE connection failed with status ${response.statusCode}: ${response.reasonPhrase}',
          uri: uri,
        );
      }

      _connected = true;

      // Parse SSE protocol stream
      String currentEvent = 'message';
      final currentData = StringBuffer();

      _bodySub = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.isEmpty) {
                // Event boundary reached: dispatch accumulated data
                if (currentData.isNotEmpty) {
                  final dataStr = currentData.toString().trim();
                  currentData.clear();
                  _handleSseEvent(currentEvent, dataStr, uri);
                  currentEvent = 'message';
                }
                return;
              }

              if (line.startsWith(':')) {
                // SSE comment / keep-alive
                return;
              }

              if (line.startsWith('event:')) {
                currentEvent = line.substring(6).trim();
              } else if (line.startsWith('data:')) {
                final d = line.substring(5).trim();
                if (currentData.isNotEmpty) currentData.write('\n');
                currentData.write(d);
              } else if (line.startsWith('endpoint:')) {
                // Non-standard direct endpoint header fallback
                _resolveEndpoint(line.substring(9).trim(), uri);
              }
            },
            onError: (err, st) {
              Log.error(_tag, 'SSE stream error', err, st);
              _connected = false;
              _stderrController.add('[SSE ERROR] $err');
            },
            onDone: () {
              Log.info(_tag, 'SSE stream closed by server');
              _connected = false;
              _stderrController.add('[SSE CLOSED]');
            },
          );
    } catch (e, st) {
      _connected = false;
      Log.error(_tag, 'Failed to connect SSE to $sseUrl', e, st);
      _stderrController.add('[SSE CONNECT FAILED] $e');
      rethrow;
    }
  }

  void _handleSseEvent(String event, String data, Uri baseUri) {
    if (event == 'endpoint') {
      _resolveEndpoint(data, baseUri);
      return;
    }

    if (event == 'message') {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          _incomingController.add(decoded);
        } else if (decoded is Map) {
          _incomingController.add(Map<String, dynamic>.from(decoded));
        }
      } catch (e) {
        _stderrController.add('[INVALID JSON IN SSE] $data');
      }
    }
  }

  void _resolveEndpoint(String relativeOrAbsolute, Uri baseUri) {
    try {
      final resolved = baseUri.resolve(relativeOrAbsolute).toString();
      _postEndpoint = resolved;
      Log.info(_tag, 'Resolved MCP POST endpoint: $resolved');
      _stderrController.add('[ENDPOINT RESOLVED] $resolved');
    } catch (e) {
      Log.warning(_tag, 'Could not resolve POST endpoint: $relativeOrAbsolute');
    }
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    if (!_connected) {
      throw StateError('Cannot send message: SSE transport not connected');
    }

    final endpoint = _postEndpoint ?? sseUrl;
    final uri = Uri.parse(endpoint);

    final reqHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...headers,
    };

    final body = jsonEncode(message);
    final res = await _client.post(uri, headers: reqHeaders, body: body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException(
        'POST to $endpoint failed (${res.statusCode}): ${res.body}',
        uri: uri,
      );
    }

    // In HTTP/Stream transport, response body might contain direct JSON-RPC response
    if (res.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          _incomingController.add(decoded);
        } else if (decoded is Map) {
          _incomingController.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Not JSON or empty response, typical for SSE post endpoints
      }
    }
  }

  @override
  Future<void> close() async {
    _connected = false;
    await _bodySub?.cancel();
    _client.close();

    if (!_incomingController.isClosed) {
      await _incomingController.close();
    }
    if (!_stderrController.isClosed) {
      await _stderrController.close();
    }
  }
}

/// Streamable HTTP transport for MCP (HTTP POST with JSON or SSE streaming response).
class McpStreamHttpTransport implements McpTransport {
  McpStreamHttpTransport({
    required this.url,
    this.headers = const {},
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  static const String _tag = 'stream_http_transport';

  final String url;
  final Map<String, String> headers;
  final http.Client _client;
  String? _sessionId;

  final StreamController<Map<String, dynamic>> _incomingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();
  bool _connected = false;

  @override
  Stream<Map<String, dynamic>> get incoming => _incomingController.stream;

  @override
  Stream<String> get stderrLines => _stderrController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _connected = true;
    Log.info(_tag, 'Ready for Streamable HTTP at $url');
    _stderrController.add('[STREAM HTTP] Ready at $url');
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    if (!_connected) {
      throw StateError('Streamable HTTP transport is not connected');
    }

    final uri = Uri.parse(url);
    final reqHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
      ...?(_sessionId != null ? {'mcp-session-id': _sessionId!} : null),
      ...headers,
    };

    final body = jsonEncode(message);
    Log.info(_tag, 'POST $url (method: ${message['method'] ?? message['id']})');

    try {
      final request = http.Request('POST', uri)
        ..headers.addAll(reqHeaders)
        ..body = body;

      final streamedResponse = await _client.send(request);

      if (streamedResponse.headers.containsKey('mcp-session-id')) {
        _sessionId = streamedResponse.headers['mcp-session-id'];
      }

      final contentType = streamedResponse.headers['content-type'] ?? '';

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        final errBody = await streamedResponse.stream.bytesToString();
        throw HttpException(
          'HTTP POST failed (${streamedResponse.statusCode}): $errBody',
          uri: uri,
        );
      }

      if (contentType.contains('text/event-stream')) {
        // Streamed SSE response
        final currentData = StringBuffer();

        await for (final line
            in streamedResponse.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          if (line.isEmpty) {
            if (currentData.isNotEmpty) {
              final dataStr = currentData.toString().trim();
              currentData.clear();
              try {
                final decoded = jsonDecode(dataStr);
                if (decoded is Map<String, dynamic>) {
                  _incomingController.add(decoded);
                } else if (decoded is Map) {
                  _incomingController.add(Map<String, dynamic>.from(decoded));
                }
              } catch (_) {}
            }
            continue;
          }
          if (line.startsWith(':') || line.startsWith('event:')) continue;
          if (line.startsWith('data:')) {
            final d = line.substring(5).trim();
            if (currentData.isNotEmpty) currentData.write('\n');
            currentData.write(d);
          }
        }
      } else {
        // Standard JSON response
        final resBody = await streamedResponse.stream.bytesToString();
        if (resBody.trim().isNotEmpty) {
          final decoded = jsonDecode(resBody);
          if (decoded is Map<String, dynamic>) {
            _incomingController.add(decoded);
          } else if (decoded is Map) {
            _incomingController.add(Map<String, dynamic>.from(decoded));
          }
        }
      }
    } catch (e, st) {
      Log.error(_tag, 'HTTP POST error', e, st);
      _stderrController.add('[HTTP ERROR] $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    _connected = false;
    _client.close();
    if (!_incomingController.isClosed) await _incomingController.close();
    if (!_stderrController.isClosed) await _stderrController.close();
  }
}

/// In-memory loopback transport for unit testing and simulations without external processes.
class McpInMemoryTransport implements McpTransport {
  McpInMemoryTransport({this.onRequest, this.onSend});

  /// Custom request handler callback for mocking responses.
  FutureOr<Map<String, dynamic>?> Function(Map<String, dynamic> message)?
  onRequest;
  void Function(Map<String, dynamic> message)? onSend;

  final StreamController<Map<String, dynamic>> _incomingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();
  bool _connected = false;

  @override
  Stream<Map<String, dynamic>> get incoming => _incomingController.stream;

  @override
  Stream<String> get stderrLines => _stderrController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  /// Emits an incoming message as if received from the server.
  void emitIncoming(Map<String, dynamic> message) {
    if (!_incomingController.isClosed) {
      _incomingController.add(message);
    }
  }

  /// Emits a log line to stderr stream.
  void emitStderr(String line) {
    if (!_stderrController.isClosed) {
      _stderrController.add(line);
    }
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    if (!_connected) throw StateError('Transport not connected');
    onSend?.call(message);

    if (onRequest != null) {
      final response = await onRequest!(message);
      if (response != null) {
        emitIncoming(response);
      }
    }
  }

  @override
  Future<void> close() async {
    _connected = false;
    if (!_incomingController.isClosed) await _incomingController.close();
    if (!_stderrController.isClosed) await _stderrController.close();
  }
}
