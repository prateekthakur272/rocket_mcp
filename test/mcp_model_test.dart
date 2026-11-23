import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/storage/server_store.dart';

void main() {
  group('McpServerConfig', () {
    test('serializes to and from JSON correctly', () {
      const config = McpServerConfig(
        id: 'test_1',
        name: 'Test Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-everything'],
        env: {'API_KEY': '12345'},
        autoConnect: true,
      );

      final json = config.toJson();
      final revived = McpServerConfig.fromJson(json);

      expect(revived.id, config.id);
      expect(revived.name, config.name);
      expect(revived.transport, McpTransportType.stdio);
      expect(revived.command, 'npx');
      expect(revived.args, ['-y', '@modelcontextprotocol/server-everything']);
      expect(revived.env['API_KEY'], '12345');
      expect(revived.autoConnect, isTrue);
    });

    test('imports from and exports to Claude Desktop configuration format', () {
      final servers = ServerStore.importFromJson('''
        {
          "mcpServers": {
            "everything": {
              "command": "npx",
              "args": ["-y", "@modelcontextprotocol/server-everything"],
              "env": {"DEBUG": "true"}
            },
            "remote-server": {
              "url": "http://localhost:3001/sse",
              "headers": {"Authorization": "Bearer token"}
            }
          }
        }
        ''');

      expect(servers.length, 2);
      final stdioServer = servers.firstWhere((s) => s.name == 'everything');
      expect(stdioServer.transport, McpTransportType.stdio);
      expect(stdioServer.command, 'npx');
      expect(stdioServer.env['DEBUG'], 'true');

      final sseServer = servers.firstWhere((s) => s.name == 'remote-server');
      expect(sseServer.transport, McpTransportType.sse);
      expect(sseServer.url, 'http://localhost:3001/sse');
      expect(sseServer.headers['Authorization'], 'Bearer token');

      final exported = ServerStore.exportClaudeFormat(servers);
      expect(exported, contains('"everything"'));
      expect(exported, contains('"remote-server"'));
    });

    test('supports Streamable HTTP and SSE transports with short labels', () {
      expect(McpTransportType.fromString('http'), McpTransportType.streamHttp);
      expect(
        McpTransportType.fromString('streamable_http'),
        McpTransportType.streamHttp,
      );
      expect(McpTransportType.fromString('sse'), McpTransportType.sse);
      expect(McpTransportType.fromString('stdio'), McpTransportType.stdio);

      expect(McpTransportType.streamHttp.shortLabel, 'http');
      expect(McpTransportType.sse.shortLabel, 'sse');
      expect(McpTransportType.stdio.shortLabel, 'stdio');

      const streamServer = McpServerConfig(
        id: 'test_http',
        name: 'Stream Server',
        transport: McpTransportType.streamHttp,
        url: 'http://localhost:8000/mcp',
      );
      final json = streamServer.toJson();
      expect(json['transport'], 'streamHttp');
      expect(json['url'], 'http://localhost:8000/mcp');

      final revived = McpServerConfig.fromJson(json);
      expect(revived.transport, McpTransportType.streamHttp);
      expect(revived.url, 'http://localhost:8000/mcp');
    });
  });

  group('McpTool & ToolResult', () {
    test('parses input schema and properties', () {
      final tool = McpTool.fromJson({
        'name': 'echo',
        'description': 'Echoes back input',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'message': {'type': 'string', 'description': 'Message to echo'},
            'count': {'type': 'integer'},
          },
          'required': ['message'],
        },
      });

      expect(tool.name, 'echo');
      expect(tool.description, 'Echoes back input');
      expect(tool.properties.containsKey('message'), isTrue);
      expect(tool.properties.containsKey('count'), isTrue);
      expect(tool.requiredProperties, contains('message'));
    });

    test('parses tool execution result with text and error states', () {
      final result = McpToolResult.fromJson({
        'content': [
          {'type': 'text', 'text': 'Hello world!'},
        ],
        'isError': false,
      });

      expect(result.isError, isFalse);
      expect(result.content.length, 1);
      expect(result.content.first.isText, isTrue);
      expect(result.fullText, 'Hello world!');
    });
  });
}
