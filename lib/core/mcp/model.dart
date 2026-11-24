import 'dart:convert';

/// Transports supported by the MCP protocol.
enum McpTransportType {
  stdio('STDIO (Local Process)'),
  sse('SSE (Server-Sent Events)'),
  streamHttp('Streamable HTTP');

  const McpTransportType(this.label);
  final String label;

  static McpTransportType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'sse' => McpTransportType.sse,
      'http' ||
      'stream' ||
      'streamhttp' ||
      'streamable_http' ||
      'streamable-http' => McpTransportType.streamHttp,
      _ => McpTransportType.stdio,
    };
  }

  String get shortLabel => switch (this) {
    McpTransportType.stdio => 'stdio',
    McpTransportType.sse => 'sse',
    McpTransportType.streamHttp => 'http',
  };
}

/// Connection status of an MCP server session.
enum McpServerStatus {
  disconnected('Disconnected'),
  connecting('Connecting'),
  connected('Connected'),
  error('Error');

  const McpServerStatus(this.label);
  final String label;
}

/// Configuration for connecting to an MCP server.
class McpServerConfig {
  const McpServerConfig({
    required this.id,
    required this.name,
    this.transport = McpTransportType.stdio,
    this.command = '',
    this.args = const [],
    this.env = const {},
    this.workingDirectory,
    this.url = '',
    this.headers = const {},
    this.autoConnect = false,
  });

  final String id;
  final String name;
  final McpTransportType transport;
  final String command;
  final List<String> args;
  final Map<String, String> env;
  final String? workingDirectory;
  final String url;
  final Map<String, String> headers;
  final bool autoConnect;

  McpServerConfig copyWith({
    String? id,
    String? name,
    McpTransportType? transport,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    String? workingDirectory,
    String? url,
    Map<String, String>? headers,
    bool? autoConnect,
  }) => McpServerConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    transport: transport ?? this.transport,
    command: command ?? this.command,
    args: args ?? this.args,
    env: env ?? this.env,
    workingDirectory: workingDirectory ?? this.workingDirectory,
    url: url ?? this.url,
    headers: headers ?? this.headers,
    autoConnect: autoConnect ?? this.autoConnect,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'transport': transport.name,
    'command': command,
    'args': args,
    'env': env,
    if (workingDirectory != null) 'workingDirectory': workingDirectory,
    'url': url,
    'headers': headers,
    'autoConnect': autoConnect,
  };

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    final rawArgs = json['args'];
    final argsList = <String>[];
    if (rawArgs is List) {
      for (final a in rawArgs) {
        if (a != null) argsList.add(a.toString());
      }
    }

    final rawEnv = json['env'];
    final envMap = <String, String>{};
    if (rawEnv is Map) {
      for (final entry in rawEnv.entries) {
        if (entry.value != null) {
          envMap[entry.key.toString()] = entry.value.toString();
        }
      }
    }

    final rawHeaders = json['headers'];
    final headersMap = <String, String>{};
    if (rawHeaders is Map) {
      for (final entry in rawHeaders.entries) {
        if (entry.value != null) {
          headersMap[entry.key.toString()] = entry.value.toString();
        }
      }
    }

    final id =
        json['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final name = json['name']?.toString() ?? 'Unnamed Server';

    return McpServerConfig(
      id: id,
      name: name,
      transport: McpTransportType.fromString(json['transport']?.toString()),
      command: json['command']?.toString() ?? '',
      args: argsList,
      env: envMap,
      workingDirectory: json['workingDirectory']?.toString(),
      url: json['url']?.toString() ?? '',
      headers: headersMap,
      autoConnect: json['autoConnect'] is bool
          ? json['autoConnect'] as bool
          : false,
    );
  }

  /// Converts standard Claude Desktop config format { "command": "...", "args": [...], "env": {...} }
  factory McpServerConfig.fromClaudeEntry(
    String name,
    Map<String, dynamic> entry,
  ) {
    final hasUrl = entry['url'] != null && entry['url'].toString().isNotEmpty;
    final transport = hasUrl ? McpTransportType.sse : McpTransportType.stdio;

    final argsList = <String>[];
    if (entry['args'] is List) {
      for (final a in (entry['args'] as List)) {
        if (a != null) argsList.add(a.toString());
      }
    }

    final envMap = <String, String>{};
    if (entry['env'] is Map) {
      for (final e in (entry['env'] as Map).entries) {
        if (e.value != null) {
          envMap[e.key.toString()] = e.value.toString();
        }
      }
    }

    final headersMap = <String, String>{};
    if (entry['headers'] is Map) {
      for (final e in (entry['headers'] as Map).entries) {
        if (e.value != null) {
          headersMap[e.key.toString()] = e.value.toString();
        }
      }
    }

    return McpServerConfig(
      id: 'server_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      transport: transport,
      command: entry['command']?.toString() ?? '',
      args: argsList,
      env: envMap,
      url: entry['url']?.toString() ?? '',
      headers: headersMap,
    );
  }

  /// Serializes to standard Claude Desktop format.
  Map<String, dynamic> toClaudeEntry() {
    if (transport == McpTransportType.sse ||
        transport == McpTransportType.streamHttp) {
      return {'url': url, if (headers.isNotEmpty) 'headers': headers};
    }
    return {'command': command, 'args': args, if (env.isNotEmpty) 'env': env};
  }
}

/// Information returned by the server on initialization.
class McpServerInfo {
  const McpServerInfo({
    required this.name,
    required this.version,
    this.instructions,
  });

  final String name;
  final String version;
  final String? instructions;

  factory McpServerInfo.fromJson(Map<String, dynamic> json) => McpServerInfo(
    name: json['name']?.toString() ?? 'Unknown Server',
    version: json['version']?.toString() ?? '1.0.0',
    instructions: json['instructions']?.toString(),
  );
}

/// Capabilities advertised by the server.
class McpCapabilities {
  const McpCapabilities({
    this.tools = false,
    this.resources = false,
    this.resourcesSubscribe = false,
    this.prompts = false,
    this.logging = false,
    this.experimental = const {},
  });

  final bool tools;
  final bool resources;
  final bool resourcesSubscribe;
  final bool prompts;
  final bool logging;
  final Map<String, dynamic> experimental;

  factory McpCapabilities.fromJson(Map<String, dynamic> json) {
    final toolsVal = json['tools'];
    final resVal = json['resources'];
    final promptsVal = json['prompts'];
    final logVal = json['logging'];
    final expVal = json['experimental'];

    return McpCapabilities(
      tools: toolsVal != null,
      resources: resVal != null,
      resourcesSubscribe: resVal is Map && resVal['subscribe'] == true,
      prompts: promptsVal != null,
      logging: logVal != null,
      experimental: expVal is Map
          ? Map<String, dynamic>.from(expVal)
          : const {},
    );
  }
}

/// A Tool exposed by the MCP server.
class McpTool {
  const McpTool({
    required this.name,
    this.description,
    this.inputSchema = const {},
  });

  final String name;
  final String? description;
  final Map<String, dynamic> inputSchema;

  factory McpTool.fromJson(Map<String, dynamic> json) => McpTool(
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
    inputSchema: json['inputSchema'] is Map
        ? Map<String, dynamic>.from(json['inputSchema'] as Map)
        : const {},
  );

  /// Returns parameter properties from the JSON schema.
  Map<String, dynamic> get properties {
    final p = inputSchema['properties'];
    return p is Map ? Map<String, dynamic>.from(p) : const {};
  }

  /// Returns required parameter names.
  List<String> get requiredProperties {
    final r = inputSchema['required'];
    if (r is List) {
      return r.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

/// Content item inside a tool result, prompt message, or resource.
class McpContent {
  const McpContent({
    required this.type,
    this.text,
    this.data,
    this.mimeType,
    this.resource,
  });

  final String type; // 'text', 'image', 'resource'
  final String? text;
  final String? data; // base64
  final String? mimeType;
  final Map<String, dynamic>? resource;

  bool get isText => type == 'text' || text != null;
  bool get isImage =>
      type == 'image' || (mimeType?.startsWith('image/') ?? false);
  bool get isResource => type == 'resource' || resource != null;

  factory McpContent.fromJson(Map<String, dynamic> json) => McpContent(
    type: json['type']?.toString() ?? 'text',
    text: json['text']?.toString(),
    data: json['data']?.toString(),
    mimeType: json['mimeType']?.toString(),
    resource: json['resource'] is Map
        ? Map<String, dynamic>.from(json['resource'] as Map)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    if (text != null) 'text': text,
    if (data != null) 'data': data,
    if (mimeType != null) 'mimeType': mimeType,
    if (resource != null) 'resource': resource,
  };
}

/// Result returned from `tools/call`.
class McpToolResult {
  const McpToolResult({required this.content, this.isError = false, this.raw});

  final List<McpContent> content;
  final bool isError;
  final Map<String, dynamic>? raw;

  String get fullText =>
      content.where((c) => c.text != null).map((c) => c.text!).join('\n');

  factory McpToolResult.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    final list = <McpContent>[];
    if (rawContent is List) {
      for (final item in rawContent) {
        if (item is Map) {
          list.add(McpContent.fromJson(Map<String, dynamic>.from(item)));
        } else if (item != null) {
          list.add(McpContent(type: 'text', text: item.toString()));
        }
      }
    }
    return McpToolResult(
      content: list,
      isError: json['isError'] == true,
      raw: json,
    );
  }

  factory McpToolResult.error(String message) => McpToolResult(
    content: [McpContent(type: 'text', text: message)],
    isError: true,
  );
}

/// A Resource exposed by the server.
class McpResource {
  const McpResource({
    required this.uri,
    required this.name,
    this.description,
    this.mimeType,
    this.size,
  });

  final String uri;
  final String name;
  final String? description;
  final String? mimeType;
  final int? size;

  factory McpResource.fromJson(Map<String, dynamic> json) => McpResource(
    uri: json['uri']?.toString() ?? '',
    name: json['name']?.toString() ?? json['uri']?.toString() ?? '',
    description: json['description']?.toString(),
    mimeType: json['mimeType']?.toString(),
    size: json['size'] is num ? (json['size'] as num).toInt() : null,
  );
}

/// A Resource Template exposed by the server.
class McpResourceTemplate {
  const McpResourceTemplate({
    required this.uriTemplate,
    required this.name,
    this.description,
    this.mimeType,
  });

  final String uriTemplate;
  final String name;
  final String? description;
  final String? mimeType;

  factory McpResourceTemplate.fromJson(Map<String, dynamic> json) =>
      McpResourceTemplate(
        uriTemplate: json['uriTemplate']?.toString() ?? '',
        name: json['name']?.toString() ?? json['uriTemplate']?.toString() ?? '',
        description: json['description']?.toString(),
        mimeType: json['mimeType']?.toString(),
      );
}

/// Content returned by `resources/read`.
class McpResourceContent {
  const McpResourceContent({
    required this.uri,
    this.mimeType,
    this.text,
    this.blob,
  });

  final String uri;
  final String? mimeType;
  final String? text;
  final String? blob;

  factory McpResourceContent.fromJson(Map<String, dynamic> json) =>
      McpResourceContent(
        uri: json['uri']?.toString() ?? '',
        mimeType: json['mimeType']?.toString(),
        text: json['text']?.toString(),
        blob: json['blob']?.toString(),
      );
}

/// A prompt argument parameter.
class McpPromptArgument {
  const McpPromptArgument({
    required this.name,
    this.description,
    this.required = false,
  });

  final String name;
  final String? description;
  final bool required;

  factory McpPromptArgument.fromJson(Map<String, dynamic> json) =>
      McpPromptArgument(
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        required: json['required'] == true,
      );
}

/// A Prompt exposed by the server.
class McpPrompt {
  const McpPrompt({
    required this.name,
    this.description,
    this.arguments = const [],
  });

  final String name;
  final String? description;
  final List<McpPromptArgument> arguments;

  factory McpPrompt.fromJson(Map<String, dynamic> json) {
    final rawArgs = json['arguments'];
    final argsList = <McpPromptArgument>[];
    if (rawArgs is List) {
      for (final a in rawArgs) {
        if (a is Map) {
          argsList.add(
            McpPromptArgument.fromJson(Map<String, dynamic>.from(a)),
          );
        }
      }
    }
    return McpPrompt(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      arguments: argsList,
    );
  }
}

/// A message in a prompt definition.
class McpPromptMessage {
  const McpPromptMessage({required this.role, required this.content});

  final String role; // 'user' or 'assistant'
  final McpContent content;

  factory McpPromptMessage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    McpContent parsedContent;
    if (rawContent is Map) {
      parsedContent = McpContent.fromJson(
        Map<String, dynamic>.from(rawContent),
      );
    } else {
      parsedContent = McpContent(
        type: 'text',
        text: rawContent?.toString() ?? '',
      );
    }
    return McpPromptMessage(
      role: json['role']?.toString() ?? 'user',
      content: parsedContent,
    );
  }
}

/// Result returned from `prompts/get`.
class McpPromptResult {
  const McpPromptResult({this.description, required this.messages});

  final String? description;
  final List<McpPromptMessage> messages;

  factory McpPromptResult.fromJson(Map<String, dynamic> json) {
    final rawMsgs = json['messages'];
    final list = <McpPromptMessage>[];
    if (rawMsgs is List) {
      for (final m in rawMsgs) {
        if (m is Map) {
          list.add(McpPromptMessage.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }
    return McpPromptResult(
      description: json['description']?.toString(),
      messages: list,
    );
  }
}

/// Log level for server logging.
enum McpLogLevel {
  debug,
  info,
  notice,
  warning,
  error,
  critical,
  alert,
  emergency;

  static McpLogLevel fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'debug' => McpLogLevel.debug,
      'notice' => McpLogLevel.notice,
      'warning' || 'warn' => McpLogLevel.warning,
      'error' => McpLogLevel.error,
      'critical' => McpLogLevel.critical,
      'alert' => McpLogLevel.alert,
      'emergency' => McpLogLevel.emergency,
      _ => McpLogLevel.info,
    };
  }
}

/// A log entry received via `notifications/message` from the server.
class McpLogMessage {
  McpLogMessage({
    required this.level,
    this.logger,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final McpLogLevel level;
  final String? logger;
  final dynamic data;
  final DateTime timestamp;

  String get dataString {
    if (data is String) return data as String;
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}

/// Standard error log entry from a running server process.
class McpStderrEntry {
  McpStderrEntry({required this.text, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  final String text;
  final DateTime timestamp;
}

/// Direction of JSON-RPC protocol messages.
enum McpMessageDirection { incoming, outgoing }

/// Type of JSON-RPC message.
enum McpMessageType { request, response, notification, error }

/// Traffic inspector log entry for JSON-RPC messages.
class McpMessageLogEntry {
  McpMessageLogEntry({
    required this.id,
    DateTime? timestamp,
    required this.direction,
    required this.type,
    this.method,
    this.jsonRpcId,
    required this.payload,
    this.durationMs,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final DateTime timestamp;
  final McpMessageDirection direction;
  final McpMessageType type;
  final String? method;
  final dynamic jsonRpcId;
  final Map<String, dynamic> payload;
  final int? durationMs;

  String get formattedPayload {
    try {
      return const JsonEncoder.withIndent('  ').convert(payload);
    } catch (_) {
      return payload.toString();
    }
  }
}

/// Root directory advertised to the server via `roots/list`.
class McpRoot {
  const McpRoot({required this.uri, this.name});

  final String uri;
  final String? name;

  Map<String, dynamic> toJson() => {'uri': uri, if (name != null) 'name': name};

  factory McpRoot.fromJson(Map<String, dynamic> json) => McpRoot(
    uri: json['uri']?.toString() ?? '',
    name: json['name']?.toString(),
  );
}
