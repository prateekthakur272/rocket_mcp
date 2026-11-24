import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Material;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/code_view.dart';
import 'package:rocket_mcp/components/json_tree.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';
import 'package:rocket_mcp/features/workspace/raw_jsonrpc_view.dart';
import 'package:rocket_mcp/theme/theme.dart';

void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('rocketmcp-raw-jsonrpc-test');
  });

  tearDown(() {
    try {
      home.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets(
    'RawJsonRpcView renders request & response panes, presets, validation, and tree toggle',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = AppState();
      const config = McpServerConfig(
        id: 'test_raw_server',
        name: 'Test Raw Server',
        command: 'echo',
      );

      final transport = McpInMemoryTransport(
        onRequest: (msg) {
          final id = msg['id'];
          final method = msg['method'];
          if (method == 'initialize') {
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'protocolVersion': '2024-11-05',
                'serverInfo': {'name': 'Mock Raw Server', 'version': '1.0.0'},
                'capabilities': {},
              },
            };
          }
          if (method == 'ping') {
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {'status': 'pong'},
            };
          }
          if (method == 'custom/echo') {
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {'received': msg['params']},
            };
          }
          return {
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': -32601, 'message': 'Method not found: $method'},
          };
        },
      );

      final session = McpSession(
        config: config,
        transportOverride: transport,
      );
      state.addServer(config);
      await session.connect();
      session.activeTab = WorkspaceTab.raw;

      await tester.pumpWidget(
        AppScope(
          state: state,
          child: PalScope(
            pal: LightPal,
            child: MaterialApp(
              home: Material(
                child: RawJsonRpcView(session: session, state: state),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify header and default empty state
      expect(find.text('REQUEST'), findsOneWidget);
      expect(find.text('RESPONSE'), findsOneWidget);
      expect(find.text('JSON-RPC 2.0'), findsOneWidget);
      expect(find.text('No response yet'), findsOneWidget);
      expect(find.text('Empty { }'), findsOneWidget);

      // 2. Test Presets menu
      await tester.tap(find.text('Presets'));
      await tester.pumpAndSettle();

      expect(find.text('COMMON MCP METHODS'), findsOneWidget);
      expect(find.text('tools/list'), findsOneWidget);
      expect(find.text('resources/list'), findsOneWidget);

      // Pick tools/list preset
      await tester.tap(find.text('tools/list'));
      await tester.pumpAndSettle();
      expect(session.rawMethod, 'tools/list');

      // 3. Test Beautify JSON parameters
      session.rawParams = '{"hello":"world","count":42}';
      session.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.text('Valid JSON'), findsOneWidget);

      // Tap beautify
      await tester.tap(find.byTooltip('Beautify JSON parameters'));
      await tester.pumpAndSettle();
      expect(session.rawParams.contains('  "hello": "world"'), isTrue);

      // 4. Test Invalid JSON parameter warning
      session.rawParams = '{"hello": broken}';
      session.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.text('Invalid JSON'), findsOneWidget);

      // 5. Send ping request and verify response
      session.rawMethod = 'ping';
      session.rawParams = '{\n}';
      session.notifyListeners();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('SUCCESS'), findsOneWidget);
      expect(find.byType(CodeView), findsOneWidget);
      expect(find.textContaining('pong'), findsWidgets);

      // 6. Test switching to Tree view
      await tester.tap(find.text('Raw JSON').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tree').last);
      await tester.pumpAndSettle();

      expect(find.byType(JsonTree), findsOneWidget);

      // 7. Clear response
      await tester.tap(find.byTooltip('Clear response'));
      await tester.pumpAndSettle();

      expect(find.text('No response yet'), findsOneWidget);

      // Flush toast timers
      await tester.pump(const Duration(seconds: 4));
    },
  );
}
