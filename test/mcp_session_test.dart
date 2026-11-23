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

    McpInMemoryTransport serverWith(
      Map<String, dynamic> capabilities,
      List<String> asked,
    ) => McpInMemoryTransport(
      onRequest: (msg) {
        final id = msg['id'];
        final method = msg['method']?.toString() ?? '';
        asked.add(method);
        Map<String, dynamic> result = {};
        switch (method) {
          case 'initialize':
            result = {
              'protocolVersion': '2024-11-05',
              'serverInfo': {'name': 'S', 'version': '1'},
              'capabilities': capabilities,
            };
          case 'tools/list':
            result = {
              'tools': [
                {'name': 't', 'inputSchema': {}},
              ],
            };
          case 'resources/list':
            result = {
              'resources': [
                {'uri': 'file:///a', 'name': 'a'},
              ],
            };
          case 'resources/templates/list':
            result = {'resourceTemplates': []};
          case 'resources/read':
            result = {
              'contents': [
                {'uri': 'file:///a', 'text': 'contents of a'},
              ],
            };
          case 'prompts/get':
            result = {
              'description': 'p',
              'messages': [
                {
                  'role': 'user',
                  'content': {'type': 'text', 'text': 'hello'},
                },
              ],
            };
          case 'prompts/list':
            result = {
              'prompts': [
                {'name': 'p'},
              ],
            };
        }
        return {'jsonrpc': '2.0', 'id': id, 'result': result};
      },
    );

    test(
      'connecting fetches tools, resources and prompts straight away',
      () async {
        final asked = <String>[];
        final session = McpSession(
          config: const McpServerConfig(id: 'all', name: 'All'),
          transportOverride: serverWith({
            'tools': {},
            'resources': {},
            'prompts': {},
          }, asked),
        );
        await session.connect();
        expect(session.status, McpServerStatus.connected);
        expect(session.isDiscovering, isFalse);
        expect(session.tools, hasLength(1));
        expect(session.resources, hasLength(1));
        expect(session.prompts, hasLength(1));
        expect(
          asked,
          containsAll(['tools/list', 'resources/list', 'prompts/list']),
        );
        await session.disconnect();
      },
    );

    test(
      'selecting loads a resource and an argument-free prompt at once',
      () async {
        final asked = <String>[];
        final session = McpSession(
          config: const McpServerConfig(id: 'auto', name: 'Auto'),
          transportOverride: serverWith({
            'resources': {},
            'prompts': {},
          }, asked),
        );
        await session.connect();
        // Let the reads started by the automatic selection finish.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(session.selectedResource?.uri, 'file:///a');
        expect(session.resourceContents?.first.text, 'contents of a');
        expect(session.selectedPrompt?.name, 'p');
        expect(session.promptResult, isNotNull);
        expect(asked, containsAll(['resources/read', 'prompts/get']));
        await session.disconnect();
      },
    );

    test('only asks for what the server advertises', () async {
      final asked = <String>[];
      final session = McpSession(
        config: const McpServerConfig(id: 'tools', name: 'Tools only'),
        transportOverride: serverWith({'tools': {}}, asked),
      );
      await session.connect();
      expect(session.tools, hasLength(1));
      expect(asked, contains('tools/list'));
      expect(asked, isNot(contains('resources/list')));
      expect(asked, isNot(contains('prompts/list')));
      await session.disconnect();
    });

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
