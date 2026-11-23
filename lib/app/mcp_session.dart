import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rocket_mcp/core/logging/log.dart';
import 'package:rocket_mcp/core/mcp/client.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';

/// Workspace tabs for inspecting and testing an MCP server.
enum WorkspaceTab {
  tools('Tools'),
  resources('Resources'),
  prompts('Prompts'),
  inspector('Traffic Inspector'),
  logs('Server Logs'),
  raw('Raw JSON-RPC');

  const WorkspaceTab(this.label);
  final String label;
}

/// Active session state for a single configured MCP server.
class McpSession extends ChangeNotifier {
  McpSession({required this.config, this.transportOverride});

  static const String _tag = 'mcp_session';

  McpServerConfig config;
  final McpTransport? transportOverride;

  McpServerStatus _status = McpServerStatus.disconnected;
  McpServerStatus get status => _status;

  String? _statusError;
  String? get statusError => _statusError;

  McpClient? _client;
  McpClient? get client => _client;

  Duration? _pingLatency;
  Duration? get pingLatency => _pingLatency;

  WorkspaceTab _activeTab = WorkspaceTab.tools;
  WorkspaceTab get activeTab => _activeTab;
  set activeTab(WorkspaceTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  // Loaded capabilities
  List<McpTool> _tools = [];
  List<McpTool> get tools => _tools;

  List<McpResource> _resources = [];
  List<McpResource> get resources => _resources;

  List<McpResourceTemplate> _resourceTemplates = [];
  List<McpResourceTemplate> get resourceTemplates => _resourceTemplates;

  List<McpPrompt> _prompts = [];
  List<McpPrompt> get prompts => _prompts;

  // Tools state
  McpTool? _selectedTool;
  McpTool? get selectedTool => _selectedTool;
  set selectedTool(McpTool? tool) {
    _selectedTool = tool;
    _toolArguments.clear();
    _toolJsonString = '{\n}';
    _lastToolResult = null;
    notifyListeners();
  }

  final Map<String, dynamic> _toolArguments = {};
  Map<String, dynamic> get toolArguments => _toolArguments;

  bool _toolJsonMode = false;
  bool get toolJsonMode => _toolJsonMode;
  set toolJsonMode(bool value) {
    _toolJsonMode = value;
    notifyListeners();
  }

  String _toolJsonString = '{\n}';
  String get toolJsonString => _toolJsonString;
  set toolJsonString(String value) {
    _toolJsonString = value;
    notifyListeners();
  }

  bool _isRunningTool = false;
  bool get isRunningTool => _isRunningTool;

  McpToolResult? _lastToolResult;
  McpToolResult? get lastToolResult => _lastToolResult;

  int? _lastToolDurationMs;
  int? get lastToolDurationMs => _lastToolDurationMs;

  // Resources state
  McpResource? _selectedResource;
  McpResource? get selectedResource => _selectedResource;
  set selectedResource(McpResource? res) {
    _selectedResource = res;
    _resourceContents = null;
    notifyListeners();
    // A resource is read as soon as it is selected.
    if (res != null) unawaited(readResource(res.uri));
  }

  List<McpResourceContent>? _resourceContents;
  List<McpResourceContent>? get resourceContents => _resourceContents;

  bool _isLoadingResource = false;
  bool get isLoadingResource => _isLoadingResource;

  final Set<String> _subscribedUris = {};
  bool isSubscribed(String uri) => _subscribedUris.contains(uri);

  // Prompts state
  McpPrompt? _selectedPrompt;
  McpPrompt? get selectedPrompt => _selectedPrompt;
  set selectedPrompt(McpPrompt? prompt) {
    _selectedPrompt = prompt;
    _promptArguments.clear();
    _promptResult = null;
    notifyListeners();
    // A prompt that needs no argument is fetched as soon as it is selected; one that does waits for its arguments.
    if (prompt != null && !prompt.arguments.any((a) => a.required)) {
      unawaited(fetchPrompt());
    }
  }

  final Map<String, String> _promptArguments = {};
  Map<String, String> get promptArguments => _promptArguments;

  McpPromptResult? _promptResult;
  McpPromptResult? get promptResult => _promptResult;

  bool _isLoadingPrompt = false;
  bool get isLoadingPrompt => _isLoadingPrompt;

  // Inspector & logs
  McpMessageLogEntry? _selectedTrafficEntry;
  McpMessageLogEntry? get selectedTrafficEntry => _selectedTrafficEntry;
  set selectedTrafficEntry(McpMessageLogEntry? entry) {
    _selectedTrafficEntry = entry;
    notifyListeners();
  }

  String _trafficFilter = '';
  String get trafficFilter => _trafficFilter;
  set trafficFilter(String query) {
    _trafficFilter = query;
    notifyListeners();
  }

  // Raw JSON-RPC state
  String _rawMethod = 'ping';
  String get rawMethod => _rawMethod;
  set rawMethod(String value) {
    _rawMethod = value;
    notifyListeners();
  }

  String _rawParams = '{\n}';
  String get rawParams => _rawParams;
  set rawParams(String value) {
    _rawParams = value;
    notifyListeners();
  }

  String? _lastRawResponse;
  String? get lastRawResponse => _lastRawResponse;

  bool _isRunningRaw = false;
  bool get isRunningRaw => _isRunningRaw;

  StreamSubscription? _trafficSub;
  StreamSubscription? _serverLogSub;
  StreamSubscription? _stderrSub;
  StreamSubscription? _toolsChangedSub;
  StreamSubscription? _resourcesChangedSub;
  StreamSubscription? _resourceUpdatedSub;
  StreamSubscription? _promptsChangedSub;

  void updateConfig(McpServerConfig newConfig) {
    config = newConfig;
    notifyListeners();
  }

  /// Connects to the MCP server.
  Future<void> connect() async {
    if (_status == McpServerStatus.connecting ||
        _status == McpServerStatus.connected) {
      return;
    }

    _status = McpServerStatus.connecting;
    _statusError = null;
    notifyListeners();

    try {
      final McpTransport transport;
      if (transportOverride != null) {
        transport = transportOverride!;
      } else if (config.transport == McpTransportType.stdio) {
        transport = McpStdioTransport(
          command: config.command,
          args: config.args,
          environment: config.env,
          workingDirectory: config.workingDirectory,
        );
      } else if (config.transport == McpTransportType.streamHttp) {
        transport = McpStreamHttpTransport(
          url: config.url,
          headers: config.headers,
        );
      } else {
        transport = McpSseTransport(
          sseUrl: config.url,
          headers: config.headers,
        );
      }

      final client = McpClient(transport: transport);
      _client = client;

      _trafficSub = client.onTraffic.listen((_) => notifyListeners());
      _serverLogSub = client.onServerLog.listen((_) => notifyListeners());
      _stderrSub = client.onStderrLine.listen((_) => notifyListeners());

      _toolsChangedSub = client.onToolsChanged.listen((_) => refreshTools());
      _resourcesChangedSub = client.onResourcesChanged.listen(
        (_) => refreshResources(),
      );
      _resourceUpdatedSub = client.onResourceUpdated.listen((uri) {
        if (_selectedResource?.uri == uri) {
          readResource(uri);
        }
      });
      _promptsChangedSub = client.onPromptsChanged.listen(
        (_) => refreshPrompts(),
      );

      await client.connect();
      _status = McpServerStatus.connected;
      _isDiscovering = true;
      // Show the connected workspace right away; its lists fill in as each answer arrives.
      notifyListeners();
      await _discover(client);
    } catch (e, st) {
      Log.error(_tag, 'Connection failed for ${config.name}', e, st);
      _status = McpServerStatus.error;
      _statusError = e.toString();
      await disconnect();
      notifyListeners();
    }
  }

  bool _isDiscovering = false;

  /// True while the lists of tools, resources and prompts are first being fetched after connecting.
  bool get isDiscovering => _isDiscovering;

  /// Fetches everything the server offers, all at once, as soon as the connection is up: the tools, resources and
  /// prompts it advertises, and a ping for the latency. A server that advertises none of them is asked for all three,
  /// since many only declare a few capabilities.
  Future<void> _discover(McpClient client) async {
    final caps = client.serverCapabilities ?? const McpCapabilities();
    final askAll = !(caps.tools || caps.resources || caps.prompts);
    try {
      await Future.wait([
        if (askAll || caps.tools) refreshTools(),
        if (askAll || caps.resources) refreshResources(),
        if (askAll || caps.prompts) refreshPrompts(),
        ping(),
      ]);
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }
  }

  /// Refreshes tools from server.
  Future<void> refreshTools() async {
    final c = _client;
    if (c == null || !c.isConnected) return;
    try {
      _tools = await c.listTools();
      if (_selectedTool != null) {
        // Re-match selected tool
        _selectedTool = _tools
            .where((t) => t.name == _selectedTool!.name)
            .firstOrNull;
      }
      if (_selectedTool == null && _tools.isNotEmpty) {
        _selectedTool = _tools.first;
      }
      notifyListeners();
    } catch (e) {
      Log.warning(_tag, 'Failed to refresh tools: $e');
    }
  }

  /// Refreshes resources and templates from server.
  Future<void> refreshResources() async {
    final c = _client;
    if (c == null || !c.isConnected) return;
    try {
      // Templates are optional: a server without them must not hide its resources.
      final lists = await Future.wait([
        c.listResources(),
        c.listResourceTemplates().catchError((Object e) {
          Log.info(_tag, 'Server has no resource templates: $e');
          return <McpResourceTemplate>[];
        }),
      ]);
      _resources = lists[0] as List<McpResource>;
      _resourceTemplates = lists[1] as List<McpResourceTemplate>;
      notifyListeners();
      if (_selectedResource == null && _resources.isNotEmpty) {
        selectedResource = _resources.first;
      }
    } catch (e) {
      Log.warning(_tag, 'Failed to refresh resources: $e');
    }
  }

  /// Refreshes prompts from server.
  Future<void> refreshPrompts() async {
    final c = _client;
    if (c == null || !c.isConnected) return;
    try {
      _prompts = await c.listPrompts();
      notifyListeners();
      if (_selectedPrompt == null && _prompts.isNotEmpty) {
        selectedPrompt = _prompts.first;
      }
    } catch (e) {
      Log.warning(_tag, 'Failed to refresh prompts: $e');
    }
  }

  /// Pings the server and updates latency.
  Future<void> ping() async {
    final c = _client;
    if (c == null || !c.isConnected) return;
    try {
      _pingLatency = await c.ping();
      notifyListeners();
    } catch (e) {
      Log.warning(_tag, 'Ping failed: $e');
    }
  }

  /// Calls the selected tool or [toolName] with arguments.
  Future<void> executeTool() async {
    final c = _client;
    final tool = _selectedTool;
    if (c == null || !c.isConnected || tool == null || _isRunningTool) return;

    _isRunningTool = true;
    _lastToolResult = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      Map<String, dynamic> args;
      if (_toolJsonMode) {
        final decoded = jsonDecode(_toolJsonString);
        args = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
      } else {
        args = Map<String, dynamic>.from(_toolArguments);
      }

      final result = await c.callTool(tool.name, args);
      stopwatch.stop();
      _lastToolDurationMs = stopwatch.elapsedMilliseconds;
      _lastToolResult = result;
    } catch (e) {
      stopwatch.stop();
      _lastToolDurationMs = stopwatch.elapsedMilliseconds;
      _lastToolResult = McpToolResult.error(e.toString());
    } finally {
      _isRunningTool = false;
      notifyListeners();
    }
  }

  /// Reads contents of the selected resource.
  Future<void> readResource([String? uri]) async {
    final c = _client;
    final targetUri = uri ?? _selectedResource?.uri;
    if (c == null || !c.isConnected || targetUri == null) return;

    _isLoadingResource = true;
    _resourceContents = null;
    notifyListeners();

    try {
      _resourceContents = await c.readResource(targetUri);
    } catch (e) {
      _resourceContents = [
        McpResourceContent(uri: targetUri, text: 'Error reading resource: $e'),
      ];
    } finally {
      _isLoadingResource = false;
      notifyListeners();
    }
  }

  /// Subscribes or unsubscribes to resource updates.
  Future<void> toggleResourceSubscription(String uri) async {
    final c = _client;
    if (c == null || !c.isConnected) return;
    try {
      if (_subscribedUris.contains(uri)) {
        await c.unsubscribeResource(uri);
        _subscribedUris.remove(uri);
      } else {
        await c.subscribeResource(uri);
        _subscribedUris.add(uri);
      }
      notifyListeners();
    } catch (e) {
      Log.warning(_tag, 'Resource subscription failed for $uri: $e');
    }
  }

  /// Fetches a prompt with arguments.
  Future<void> fetchPrompt() async {
    final c = _client;
    final prompt = _selectedPrompt;
    if (c == null || !c.isConnected || prompt == null || _isLoadingPrompt) {
      return;
    }

    _isLoadingPrompt = true;
    _promptResult = null;
    notifyListeners();

    try {
      _promptResult = await c.getPrompt(prompt.name, _promptArguments);
    } catch (e) {
      _promptResult = McpPromptResult(
        description: 'Error fetching prompt: $e',
        messages: const [],
      );
    } finally {
      _isLoadingPrompt = false;
      notifyListeners();
    }
  }

  /// Sends a raw custom JSON-RPC request to the server.
  Future<void> sendRawJsonRpc() async {
    final c = _client;
    if (c == null || !c.isConnected || _isRunningRaw) return;

    _isRunningRaw = true;
    _lastRawResponse = null;
    notifyListeners();

    try {
      Map<String, dynamic>? params;
      final trimmed = _rawParams.trim();
      if (trimmed.isNotEmpty) {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          params = Map<String, dynamic>.from(decoded);
        }
      }

      final res = await c.sendRequest(_rawMethod.trim(), params);
      _lastRawResponse = const JsonEncoder.withIndent('  ').convert(res);
    } catch (e) {
      _lastRawResponse = 'Error: $e';
    } finally {
      _isRunningRaw = false;
      notifyListeners();
    }
  }

  /// Disconnects the session and frees client resources.
  Future<void> disconnect() async {
    _status = McpServerStatus.disconnected;
    _isDiscovering = false;
    _pingLatency = null;
    await _trafficSub?.cancel();
    await _serverLogSub?.cancel();
    await _stderrSub?.cancel();
    await _toolsChangedSub?.cancel();
    await _resourcesChangedSub?.cancel();
    await _resourceUpdatedSub?.cancel();
    await _promptsChangedSub?.cancel();

    final c = _client;
    _client = null;
    if (c != null) {
      await c.close();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
