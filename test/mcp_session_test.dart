import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';

void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('rocketmcp-session-test');
    AppStore.homeOverride = home.path;
  });

  tearDown(() {
    AppStore.homeOverride = null;
    home.deleteSync(recursive: true);
  });

  group('McpSession', () {
    test(
      'connects, loads tools and executes tool with form arguments',
      () async {
        final transport = McpInMemoryTransport(
          onRequest: (msg) {
            final id = msg['id'];
            final method = msg['method']?.toString();

            if (method == 'initialize') {
              return {
                'jsonrpc': '2.0',
                'id': id,
                'result': {
                  'protocolVersion': '2024-11-05',
                  'serverInfo': {
                    'name': 'Session Test Server',
                    'version': '1.0.0',
                  },
                  'capabilities': {'tools': {}},
                },
              };
            }
            if (method == 'tools/list') {
              return {
                'jsonrpc': '2.0',
                'id': id,
                'result': {
                  'tools': [
                    {
                      'name': 'greet',
                      'description': 'Greets user',
                      'inputSchema': {
                        'type': 'object',
                        'properties': {
                          'name': {'type': 'string'},
                        },
                        'required': ['name'],
                      },
                    },
                  ],
                },
              };
            }
            if (method == 'tools/call') {
              final args = (msg['params'] as Map)['arguments'] as Map;
              return {
                'jsonrpc': '2.0',
                'id': id,
                'result': {
                  'content': [
                    {'type': 'text', 'text': 'Hello, ${args["name"]}!'},
                  ],
                  'isError': false,
                },
              };
            }
            return {'jsonrpc': '2.0', 'id': id, 'result': {}};
          },
        );

        final session = McpSession(
          config: const McpServerConfig(
            id: 'test_server',
            name: 'Session Test Server',
          ),
          transportOverride: transport,
        );

        await session.connect();

        expect(session.status, McpServerStatus.connected);
        expect(session.tools.length, 1);
        expect(session.selectedTool?.name, 'greet');

        // Set tool argument and execute
        session.toolArguments['name'] = 'Alice';
        await session.executeTool();

        expect(session.lastToolResult, isNotNull);
        expect(session.lastToolResult?.isError, isFalse);
        expect(session.lastToolResult?.fullText, 'Hello, Alice!');

        await session.disconnect();
        expect(session.status, McpServerStatus.disconnected);
      },
    );

    test('supports switching tabs between tools, resources, traffic, logs', () {
      final session = McpSession(
        config: const McpServerConfig(id: 'tab_test', name: 'Tab Test'),
      );

      expect(session.activeTab, WorkspaceTab.tools);
      session.activeTab = WorkspaceTab.inspector;
      expect(session.activeTab, WorkspaceTab.inspector);
      session.activeTab = WorkspaceTab.resources;
      expect(session.activeTab, WorkspaceTab.resources);
      session.activeTab = WorkspaceTab.logs;
      expect(session.activeTab, WorkspaceTab.logs);
      session.activeTab = WorkspaceTab.raw;
      expect(session.activeTab, WorkspaceTab.raw);
    });
  });
}
