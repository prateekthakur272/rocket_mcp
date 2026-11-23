import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rocket_mcp/core/logging/log.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';

/// Manages persistence of configured MCP servers and test request history.
final class ServerStore {
  const ServerStore._();

  static const String _tag = 'server_store';

  static String get _serversFile => p.join(AppStore.dir, 'servers.json');

  /// Built-in templates for popular and testing MCP servers.
  static List<McpServerConfig> get builtInPresets => [
    const McpServerConfig(
      id: 'preset_everything',
      name: 'Everything Server (Reference/Testing)',
      transport: McpTransportType.stdio,
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-everything'],
    ),
    const McpServerConfig(
      id: 'preset_memory',
      name: 'Memory Server (Knowledge Graph)',
      transport: McpTransportType.stdio,
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-memory'],
    ),
    const McpServerConfig(
      id: 'preset_stream_http',
      name: 'Streamable HTTP Server (Sample)',
      transport: McpTransportType.streamHttp,
      url: 'http://localhost:8000/mcp',
      headers: {'Accept': 'application/json, text/event-stream'},
    ),
    const McpServerConfig(
      id: 'preset_sse_local',
      name: 'Local SSE Server (Sample)',
      transport: McpTransportType.sse,
      url: 'http://localhost:3001/sse',
    ),
    const McpServerConfig(
      id: 'preset_filesystem',
      name: 'Filesystem Server',
      transport: McpTransportType.stdio,
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-filesystem', '.'],
    ),
    const McpServerConfig(
      id: 'preset_fetch',
      name: 'Fetch Server (Web)',
      transport: McpTransportType.stdio,
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-fetch'],
    ),
    const McpServerConfig(
      id: 'preset_sqlite',
      name: 'SQLite Server',
      transport: McpTransportType.stdio,
      command: 'uvx',
      args: ['mcp-server-sqlite', '--db-path', 'test.db'],
    ),
  ];

  /// Loads configured servers from disk. If no servers exist yet, returns initial presets.
  static List<McpServerConfig> loadServers() {
    try {
      final file = File(_serversFile);
      if (!file.existsSync()) {
        return [
          builtInPresets[0],
          builtInPresets[1],
          builtInPresets[2],
          builtInPresets[3],
        ];
      }

      final text = file.readAsStringSync();
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => McpServerConfig.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [
        builtInPresets[0],
        builtInPresets[1],
        builtInPresets[2],
        builtInPresets[3],
      ];
    } catch (e, st) {
      Log.warning(_tag, 'Cannot read $_serversFile, using defaults', e, st);
      return [
        builtInPresets[0],
        builtInPresets[1],
        builtInPresets[2],
        builtInPresets[3],
      ];
    }
  }

  /// Saves the list of servers to disk.
  static void saveServers(List<McpServerConfig> servers) {
    try {
      final jsonList = servers.map((s) => s.toJson()).toList();
      final file = File(_serversFile);
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(jsonList),
      );
    } catch (e, st) {
      Log.error(_tag, 'Cannot save servers to $_serversFile', e, st);
    }
  }

  /// Exports server configurations in the standard Claude Desktop format:
  /// `{ "mcpServers": { "<name>": { "command": "...", "args": [...] } } }`
  static String exportClaudeFormat(List<McpServerConfig> servers) {
    final mcpServers = <String, dynamic>{};
    for (final s in servers) {
      mcpServers[s.name] = s.toClaudeEntry();
    }
    return const JsonEncoder.withIndent('  ')
        .convert({'mcpServers': mcpServers});
  }

  /// Imports server configurations from a JSON string (Claude config, array of servers, or Rocket format).
  static List<McpServerConfig> importFromJson(String jsonString) {
    final decoded = jsonDecode(jsonString);
    final results = <McpServerConfig>[];

    if (decoded is Map) {
      final serversMap = decoded['mcpServers'];
      if (serversMap is Map) {
        for (final entry in serversMap.entries) {
          if (entry.value is Map) {
            results.add(
              McpServerConfig.fromClaudeEntry(
                entry.key.toString(),
                Map<String, dynamic>.from(entry.value as Map),
              ),
            );
          }
        }
        return results;
      }

      // Check if it's a single server configuration
      if (decoded.containsKey('name') ||
          decoded.containsKey('command') ||
          decoded.containsKey('url')) {
        results.add(
          McpServerConfig.fromJson(Map<String, dynamic>.from(decoded)),
        );
        return results;
      }
    } else if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) {
          results.add(
            McpServerConfig.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return results;
  }
}
