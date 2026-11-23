import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/core/mcp/client.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';

void main() {
  group('McpClient protocol & features', () {
    late McpInMemoryTransport transport;
    late McpClient client;
    final sentMessages = <Map<String, dynamic>>[];

    setUp(() {
      sentMessages.clear();
      transport = McpInMemoryTransport(
        onSend: (msg) => sentMessages.add(msg),
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
                  'name': 'Mock Testing Server',
                  'version': '2.1.0',
                },
                'capabilities': {
                  'tools': {},
                  'resources': {'subscribe': true},
                  'prompts': {},
                  'logging': {},
                },
              },
            };
          }

          if (method == 'ping') {
            return {'jsonrpc': '2.0', 'id': id, 'result': {}};
          }

          if (method == 'tools/list') {
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'tools': [
                  {
                    'name': 'calculator',
                    'description': 'Performs calculations',
                    'inputSchema': {
                      'type': 'object',
                      'properties': {
                        'expression': {'type': 'string'},
                      },
                      'required': ['expression'],
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
                  {
                    'type': 'text',
                    'text': 'Result of ${args["expression"]} = 42',
                  },
                ],
                'isError': false,
              },
            };
          }

          if (method == 'resources/list') {
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'resources': [
                  {
                    'uri': 'memo://today',
                    'name': 'Today Note',
                    'mimeType': 'text/plain',
                  },
                ],
              },
            };
          }

          if (method == 'resources/templates/list') {
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'resourceTemplates': [
                  {'uriTemplate': 'memo://{id}', 'name': 'Memo Note'},
                ],
              },
            };
          }

          if (method == 'resources/read') {
            final uri = (msg['params'] as Map)['uri']?.toString();
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'contents': [
                  {
                    'uri': uri,
                    'mimeType': 'text/plain',
                    'text': 'Note content for $uri',
                  },
                ],
              },
            };
          }

          if (method == 'prompts/list') {
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'prompts': [
                  {
                    'name': 'review_code',
                    'description': 'Reviews code diff',
                    'arguments': [
                      {'name': 'diff', 'required': true},
                    ],
                  },
                ],
              },
            };
          }

          if (method == 'prompts/get') {
            final args = (msg['params'] as Map)['arguments'] as Map;
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'description': 'Code review prompt',
                'messages': [
                  {
                    'role': 'user',
                    'content': {
                      'type': 'text',
                      'text': 'Please review: ${args["diff"]}',
                    },
                  },
                ],
              },
            };
          }

          return null;
        },
      );

      client = McpClient(
        transport: transport,
        roots: [const McpRoot(uri: 'file:///workspace', name: 'workspace')],
      );
    });

    tearDown(() async {
      await client.close();
    });

    test('performs full handshake and initializes session', () async {
      await client.connect();

      expect(client.isConnected, isTrue);
      expect(client.serverInfo?.name, 'Mock Testing Server');
      expect(client.serverInfo?.version, '2.1.0');
      expect(client.serverCapabilities?.tools, isTrue);
      expect(client.serverCapabilities?.resourcesSubscribe, isTrue);

      // Verify that initialized notification was sent immediately after initialize
      final initNotifications = sentMessages.where(
        (m) => m['method'] == 'notifications/initialized',
      );
      expect(initNotifications.length, 1);
    });

    test('measures ping latency successfully', () async {
      await client.connect();
      final latency = await client.ping();
      expect(latency.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('lists tools and executes tool with arguments', () async {
      await client.connect();

      final tools = await client.listTools();
      expect(tools.length, 1);
      expect(tools.first.name, 'calculator');

      final result = await client.callTool('calculator', {
        'expression': '6 * 7',
      });
      expect(result.isError, isFalse);
      expect(result.fullText, 'Result of 6 * 7 = 42');
    });

    test('lists and reads resources', () async {
      await client.connect();

      final resources = await client.listResources();
      expect(resources.length, 1);
      expect(resources.first.uri, 'memo://today');

      final templates = await client.listResourceTemplates();
      expect(templates.length, 1);
      expect(templates.first.uriTemplate, 'memo://{id}');

      final contents = await client.readResource('memo://today');
      expect(contents.length, 1);
      expect(contents.first.text, 'Note content for memo://today');
    });

    test('lists and gets prompts with arguments', () async {
      await client.connect();

      final prompts = await client.listPrompts();
      expect(prompts.length, 1);
      expect(prompts.first.name, 'review_code');

      final promptRes = await client.getPrompt('review_code', {
        'diff': 'line 1 + line 2',
      });
      expect(promptRes.messages.length, 1);
      expect(
        promptRes.messages.first.content.text,
        'Please review: line 1 + line 2',
      );
    });

    test('handles server-initiated roots/list requests', () async {
      await client.connect();

      // Emit server request for roots/list
      transport.emitIncoming({
        'jsonrpc': '2.0',
        'id': 999,
        'method': 'roots/list',
      });

      await pumpEventQueue();

      final rootResponses = sentMessages.where((m) => m['id'] == 999);
      expect(rootResponses.length, 1);
      final res = rootResponses.first;
      final roots = (res['result'] as Map)['roots'] as List;
      expect(roots.length, 1);
      expect((roots.first as Map)['uri'], 'file:///workspace');
    });

    test('records real-time JSON-RPC traffic inspector entries', () async {
      await client.connect();
      await client.listTools();

      final traffic = client.trafficHistory;
      expect(
        traffic.length,
        greaterThanOrEqualTo(4),
      ); // init req, init resp, init notif, tools/list req, tools/list resp

      expect(
        traffic.any(
          (t) =>
              t.method == 'initialize' &&
              t.direction == McpMessageDirection.outgoing,
        ),
        isTrue,
      );
      expect(
        traffic.any(
          (t) =>
              t.type == McpMessageType.response &&
              t.direction == McpMessageDirection.incoming,
        ),
        isTrue,
      );
    });

    test('handles notifications/message server logs', () async {
      await client.connect();

      transport.emitIncoming({
        'jsonrpc': '2.0',
        'method': 'notifications/message',
        'params': {
          'level': 'info',
          'logger': 'test_logger',
          'data': 'Operation finished successfully',
        },
      });

      await pumpEventQueue();

      expect(client.serverLogs.length, 1);
      expect(client.serverLogs.first.level, McpLogLevel.info);
      expect(
        client.serverLogs.first.dataString,
        'Operation finished successfully',
      );
    });
  });
}
