import 'dart:async';

import 'package:rocket_mcp/core/logging/log.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';

/// Exception thrown when an MCP JSON-RPC operation fails or server returns an error.
class McpException implements Exception {
  const McpException(this.message, {this.code, this.data});

  final String message;
  final int? code;
  final dynamic data;

  @override
  String toString() => code != null
      ? 'McpException [$code]: $message'
      : 'McpException: $message';
}

/// A full-featured Model Context Protocol (MCP) client.
class McpClient {
  McpClient({
    required this.transport,
    this.requestTimeout = const Duration(seconds: 30),
    List<McpRoot>? roots,
  }) : roots = List.of(roots ?? const []);

  static const String _tag = 'mcp_client';
  static const String protocolVersion = '2024-11-05';

  final McpTransport transport;
  final Duration requestTimeout;
  final List<McpRoot> roots;

  int _nextId = 1;
  final Map<dynamic, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final Map<dynamic, DateTime> _requestTimestamps = {};

  StreamSubscription<Map<String, dynamic>>? _incomingSub;
  StreamSubscription<String>? _stderrSub;

  McpServerInfo? _serverInfo;
  McpCapabilities? _serverCapabilities;
  String? _negotiatedProtocolVersion;

  McpServerInfo? get serverInfo => _serverInfo;
  McpCapabilities? get serverCapabilities => _serverCapabilities;
  String? get negotiatedProtocolVersion => _negotiatedProtocolVersion;

  final List<McpMessageLogEntry> _trafficHistory = [];
  final StreamController<McpMessageLogEntry> _trafficController =
      StreamController<McpMessageLogEntry>.broadcast();

  final List<McpLogMessage> _serverLogs = [];
  final StreamController<McpLogMessage> _serverLogsController =
      StreamController<McpLogMessage>.broadcast();

  final List<McpStderrEntry> _stderrEntries = [];
  final StreamController<String> _stderrLinesController =
      StreamController<String>.broadcast();

  // Notification stream controllers
  final StreamController<void> _toolsChangedController =
      StreamController<void>.broadcast();
  final StreamController<void> _resourcesChangedController =
      StreamController<void>.broadcast();
  final StreamController<String> _resourceUpdatedController =
      StreamController<String>.broadcast();
  final StreamController<void> _promptsChangedController =
      StreamController<void>.broadcast();

  List<McpMessageLogEntry> get trafficHistory =>
      List.unmodifiable(_trafficHistory);
  Stream<McpMessageLogEntry> get onTraffic => _trafficController.stream;

  List<McpLogMessage> get serverLogs => List.unmodifiable(_serverLogs);
  Stream<McpLogMessage> get onServerLog => _serverLogsController.stream;

  List<McpStderrEntry> get stderrEntries => List.unmodifiable(_stderrEntries);
  List<String> get stderrLogLines =>
      List.unmodifiable(_stderrEntries.map((e) => e.text));
  Stream<String> get onStderrLine => _stderrLinesController.stream;

  Stream<void> get onToolsChanged => _toolsChangedController.stream;
  Stream<void> get onResourcesChanged => _resourcesChangedController.stream;
  Stream<String> get onResourceUpdated => _resourceUpdatedController.stream;
  Stream<void> get onPromptsChanged => _promptsChangedController.stream;

  bool get isConnected => transport.isConnected;

  static Map<String, dynamic> _extractResult(Map<String, dynamic> res) {
    final raw = res['result'];
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
  }

  /// Connects transport, initializes MCP session, and completes the handshake.
  Future<void> connect() async {
    Log.info(_tag, 'Connecting transport...');
    await transport.connect();

    _incomingSub = transport.incoming.listen(
      _handleIncomingMessage,
      onError: (err, st) {
        Log.error(_tag, 'Incoming transport stream error', err, st);
      },
      onDone: () {
        Log.info(_tag, 'Incoming transport stream finished');
        _failPendingRequests('Transport closed');
      },
    );

    _stderrSub = transport.stderrLines.listen((line) {
      final entry = McpStderrEntry(text: line);
      _stderrEntries.add(entry);
      _stderrLinesController.add(line);
    });

    // MCP Handshake: initialize
    Log.info(_tag, 'Sending initialize request...');
    final initResponse = await sendRequest('initialize', {
      'protocolVersion': protocolVersion,
      'capabilities': {
        'roots': {'listChanged': true},
        'sampling': {},
      },
      'clientInfo': {'name': 'Rocket MCP', 'version': '1.0.0'},
    });

    final result = _extractResult(initResponse);
    _negotiatedProtocolVersion =
        result['protocolVersion']?.toString() ?? protocolVersion;

    if (result['serverInfo'] is Map) {
      _serverInfo = McpServerInfo.fromJson(
        Map<String, dynamic>.from(result['serverInfo'] as Map),
      );
    }

    if (result['capabilities'] is Map) {
      _serverCapabilities = McpCapabilities.fromJson(
        Map<String, dynamic>.from(result['capabilities'] as Map),
      );
    } else {
      _serverCapabilities = const McpCapabilities();
    }

    // Immediately send initialized notification as required by spec
    await sendNotification('notifications/initialized');
    Log.info(
      _tag,
      'Initialized session with ${_serverInfo?.name ?? "server"} (protocol $_negotiatedProtocolVersion)',
    );
  }

  /// Sends a JSON-RPC request and returns the full JSON-RPC response map.
  Future<Map<String, dynamic>> sendRequest(
    String method, [
    Map<String, dynamic>? params,
  ]) async {
    final id = _nextId++;
    final payload = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': ?params,
    };

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;
    final now = DateTime.now();
    _requestTimestamps[id] = now;

    _recordTraffic(
      direction: McpMessageDirection.outgoing,
      type: McpMessageType.request,
      method: method,
      jsonRpcId: id,
      payload: payload,
    );

    try {
      await transport.send(payload);
    } catch (e) {
      _pendingRequests.remove(id);
      _requestTimestamps.remove(id);
      rethrow;
    }

    return completer.future.timeout(
      requestTimeout,
      onTimeout: () {
        _pendingRequests.remove(id);
        _requestTimestamps.remove(id);
        throw TimeoutException(
          'Request $method (id: $id) timed out after $requestTimeout',
        );
      },
    );
  }

  /// Sends a JSON-RPC notification (no response expected).
  Future<void> sendNotification(
    String method, [
    Map<String, dynamic>? params,
  ]) async {
    final payload = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      'params': ?params,
    };

    _recordTraffic(
      direction: McpMessageDirection.outgoing,
      type: McpMessageType.notification,
      method: method,
      payload: payload,
    );

    await transport.send(payload);
  }

  /// Measures round-trip ping latency.
  Future<Duration> ping() async {
    final start = DateTime.now();
    await sendRequest('ping');
    return DateTime.now().difference(start);
  }

  // ==========================================
  // Tools
  // ==========================================

  /// Lists tools supported by the server, following pagination cursors.
  Future<List<McpTool>> listTools() async {
    final tools = <McpTool>[];
    String? cursor;

    do {
      final res = await sendRequest(
        'tools/list',
        cursor != null ? {'cursor': cursor} : null,
      );
      final result = _extractResult(res);
      final list = result['tools'];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            tools.add(McpTool.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      cursor = result['nextCursor']?.toString();
    } while (cursor != null && cursor.isNotEmpty);

    return tools;
  }

  /// Executes a tool with the provided arguments.
  Future<McpToolResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    final res = await sendRequest('tools/call', {
      'name': name,
      'arguments': arguments,
    });
    final rawResult = res['result'];
    if (rawResult is Map) {
      return McpToolResult.fromJson(Map<String, dynamic>.from(rawResult));
    }
    return McpToolResult.error('Invalid response format for tools/call');
  }

  // ==========================================
  // Resources
  // ==========================================

  /// Lists all static resources advertised by the server.
  Future<List<McpResource>> listResources() async {
    final resources = <McpResource>[];
    String? cursor;

    do {
      final res = await sendRequest(
        'resources/list',
        cursor != null ? {'cursor': cursor} : null,
      );
      final result = _extractResult(res);
      final list = result['resources'];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            resources.add(
              McpResource.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
      cursor = result['nextCursor']?.toString();
    } while (cursor != null && cursor.isNotEmpty);

    return resources;
  }

  /// Lists all resource templates advertised by the server.
  Future<List<McpResourceTemplate>> listResourceTemplates() async {
    final templates = <McpResourceTemplate>[];
    final res = await sendRequest('resources/templates/list');
    final result = _extractResult(res);
    final list = result['resourceTemplates'];
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          templates.add(
            McpResourceTemplate.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return templates;
  }

  /// Reads contents of a given resource URI.
  Future<List<McpResourceContent>> readResource(String uri) async {
    final res = await sendRequest('resources/read', {'uri': uri});
    final result = _extractResult(res);
    final rawContents = result['contents'];
    final list = <McpResourceContent>[];
    if (rawContents is List) {
      for (final c in rawContents) {
        if (c is Map) {
          list.add(McpResourceContent.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    return list;
  }

  /// Subscribes to updates for a resource URI.
  Future<void> subscribeResource(String uri) async {
    await sendRequest('resources/subscribe', {'uri': uri});
  }

  /// Unsubscribes from updates for a resource URI.
  Future<void> unsubscribeResource(String uri) async {
    await sendRequest('resources/unsubscribe', {'uri': uri});
  }

  // ==========================================
  // Prompts
  // ==========================================

  /// Lists prompts offered by the server.
  Future<List<McpPrompt>> listPrompts() async {
    final prompts = <McpPrompt>[];
    String? cursor;

    do {
      final res = await sendRequest(
        'prompts/list',
        cursor != null ? {'cursor': cursor} : null,
      );
      final result = _extractResult(res);
      final list = result['prompts'];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            prompts.add(McpPrompt.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      cursor = result['nextCursor']?.toString();
    } while (cursor != null && cursor.isNotEmpty);

    return prompts;
  }

  /// Retrieves a prompt with arguments filled in.
  Future<McpPromptResult> getPrompt(
    String name,
    Map<String, String> arguments,
  ) async {
    final res = await sendRequest('prompts/get', {
      'name': name,
      if (arguments.isNotEmpty) 'arguments': arguments,
    });
    final result = _extractResult(res);
    return McpPromptResult.fromJson(result);
  }

  // ==========================================
  // Logging & Configuration
  // ==========================================

  /// Sets the minimum server logging level.
  Future<void> setLogLevel(McpLogLevel level) async {
    await sendRequest('logging/setLevel', {'level': level.name});
  }

  /// Adds a workspace root and notifies server.
  Future<void> addRoot(McpRoot root) async {
    roots.add(root);
    await sendNotification('notifications/roots/list_changed');
  }

  /// Removes a workspace root and notifies server.
  Future<void> removeRoot(String uri) async {
    roots.removeWhere((r) => r.uri == uri);
    await sendNotification('notifications/roots/list_changed');
  }

  /// Clears recorded traffic log.
  void clearTraffic() {
    _trafficHistory.clear();
  }

  /// Clears server log stream history.
  void clearLogs() {
    _serverLogs.clear();
    _stderrEntries.clear();
  }

  // ==========================================
  // Internal JSON-RPC Message Handling
  // ==========================================

  void _handleIncomingMessage(Map<String, dynamic> msg) {
    final id = msg['id'];
    final method = msg['method']?.toString();
    final hasError = msg.containsKey('error');

    int? durationMs;
    if (id != null && _requestTimestamps.containsKey(id)) {
      final sentAt = _requestTimestamps.remove(id)!;
      durationMs = DateTime.now().difference(sentAt).inMilliseconds;
    }

    // Determine message type
    final McpMessageType type;
    if (method != null && id != null) {
      type = McpMessageType.request; // Server-initiated request
    } else if (method != null) {
      type = McpMessageType.notification; // Server notification
    } else if (hasError) {
      type = McpMessageType.error;
    } else {
      type = McpMessageType.response;
    }

    _recordTraffic(
      direction: McpMessageDirection.incoming,
      type: type,
      method: method,
      jsonRpcId: id,
      payload: msg,
      durationMs: durationMs,
    );

    // 1. Response to a pending request
    if (id != null && _pendingRequests.containsKey(id)) {
      final completer = _pendingRequests.remove(id)!;
      if (hasError) {
        final err = msg['error'];
        final code = err is Map ? err['code'] as int? : null;
        final message = err is Map
            ? err['message']?.toString() ?? 'Error'
            : err.toString();
        final data = err is Map ? err['data'] : null;
        completer.completeError(McpException(message, code: code, data: data));
      } else {
        completer.complete(msg);
      }
      return;
    }

    // 2. Server-initiated request (e.g. roots/list, ping, sampling)
    if (method != null && id != null) {
      _handleServerRequest(id, method, msg['params']);
      return;
    }

    // 3. Server-initiated notification
    if (method != null) {
      _handleServerNotification(method, msg['params']);
    }
  }

  void _handleServerRequest(dynamic id, String method, dynamic params) async {
    Log.info(_tag, 'Server sent request: $method (id: $id)');
    try {
      if (method == 'roots/list') {
        // Return configured client workspace roots
        final response = {
          'jsonrpc': '2.0',
          'id': id,
          'result': {'roots': roots.map((r) => r.toJson()).toList()},
        };
        _recordTraffic(
          direction: McpMessageDirection.outgoing,
          type: McpMessageType.response,
          jsonRpcId: id,
          payload: response,
        );
        await transport.send(response);
      } else if (method == 'ping') {
        final response = {'jsonrpc': '2.0', 'id': id, 'result': {}};
        await transport.send(response);
      } else {
        // Unsupported server request: reply with MethodNotFound (-32601)
        final response = {
          'jsonrpc': '2.0',
          'id': id,
          'error': {
            'code': -32601,
            'message': 'Method not implemented by client: $method',
          },
        };
        _recordTraffic(
          direction: McpMessageDirection.outgoing,
          type: McpMessageType.error,
          jsonRpcId: id,
          payload: response,
        );
        await transport.send(response);
      }
    } catch (e, st) {
      Log.error(_tag, 'Error handling server request $method', e, st);
    }
  }

  void _handleServerNotification(String method, dynamic params) {
    if (method == 'notifications/message') {
      if (params is Map) {
        final level = McpLogLevel.fromString(params['level']?.toString());
        final logger = params['logger']?.toString();
        final data = params['data'];
        final logMsg = McpLogMessage(level: level, logger: logger, data: data);
        _serverLogs.add(logMsg);
        _serverLogsController.add(logMsg);
      }
    } else if (method == 'notifications/tools/list_changed') {
      _toolsChangedController.add(null);
    } else if (method == 'notifications/resources/list_changed') {
      _resourcesChangedController.add(null);
    } else if (method == 'notifications/resources/updated') {
      final uri = params is Map ? params['uri']?.toString() ?? '' : '';
      _resourceUpdatedController.add(uri);
    } else if (method == 'notifications/prompts/list_changed') {
      _promptsChangedController.add(null);
    }
  }

  void _recordTraffic({
    required McpMessageDirection direction,
    required McpMessageType type,
    String? method,
    dynamic jsonRpcId,
    required Map<String, dynamic> payload,
    int? durationMs,
  }) {
    final entry = McpMessageLogEntry(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      direction: direction,
      type: type,
      method: method ?? payload['method']?.toString(),
      jsonRpcId: jsonRpcId,
      payload: payload,
      durationMs: durationMs,
    );

    _trafficHistory.add(entry);
    if (!_trafficController.isClosed) {
      _trafficController.add(entry);
    }
  }

  void _failPendingRequests(String reason) {
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(McpException(reason));
      }
    }
    _pendingRequests.clear();
    _requestTimestamps.clear();
  }

  /// Closes the client, unsubscribes listeners, and terminates the transport.
  Future<void> close() async {
    _failPendingRequests('Client closed');
    await _incomingSub?.cancel();
    await _stderrSub?.cancel();
    await transport.close();

    if (!_trafficController.isClosed) await _trafficController.close();
    if (!_serverLogsController.isClosed) await _serverLogsController.close();
    if (!_stderrLinesController.isClosed) await _stderrLinesController.close();
    if (!_toolsChangedController.isClosed) {
      await _toolsChangedController.close();
    }
    if (!_resourcesChangedController.isClosed) {
      await _resourcesChangedController.close();
    }
    if (!_resourceUpdatedController.isClosed) {
      await _resourceUpdatedController.close();
    }
    if (!_promptsChangedController.isClosed) {
      await _promptsChangedController.close();
    }
  }
}
