import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, SelectableText, Material;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/workspace/server_logs_view.dart';
import 'package:rocket_mcp/theme/theme.dart';

void main() {
  late Directory tempHome;

  setUp(() {
    tempHome = Directory.systemTemp.createTempSync('rocketmcp-logs-test');
    AppStore.homeOverride = tempHome.path;
  });

  tearDown(() {
    AppStore.homeOverride = null;
    tempHome.deleteSync(recursive: true);
  });

  Widget wrapWithTheme(McpSession session, AppState state) {
    return AppScope(
      state: state,
      child: PalScope(
        pal: DarkPal,
        child: MaterialApp(
          home: Material(
            child: ServerLogsView(session: session),
          ),
        ),
      ),
    );
  }

  testWidgets('ServerLogsView renders empty state and then real-time log lines', (tester) async {
    final state = AppState();
    final config = const McpServerConfig(
      id: 'test_server',
      name: 'Test Server',
      command: 'echo',
    );

    final transport = McpInMemoryTransport(
      onRequest: (msg) {
        if (msg['method'] == 'initialize') {
          return {
            'jsonrpc': '2.0',
            'id': msg['id'],
            'result': {
              'protocolVersion': '2024-11-05',
              'serverInfo': {'name': 'Mock Server', 'version': '1.0.0'},
              'capabilities': {},
            },
          };
        }
        return {'jsonrpc': '2.0', 'id': msg['id'], 'result': {}};
      },
    );

    final session = McpSession(
      config: config,
      transportOverride: transport,
    );

    // Initial empty state
    await tester.pumpWidget(wrapWithTheme(session, state));
    await tester.pumpAndSettle();

    expect(find.text('No server logs yet'), findsOneWidget);
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('STDERR'), findsOneWidget);

    // Connect session with mock transport
    await session.connect();

    // Emit logs
    transport.emitStderr('Failed to connect to database at localhost:5432');
    transport.emitIncoming({
      'jsonrpc': '2.0',
      'method': 'notifications/message',
      'params': {
        'level': 'info',
        'logger': 'db-pool',
        'data': 'Connection pool initialized with 5 workers',
      },
    });
    transport.emitIncoming({
      'jsonrpc': '2.0',
      'method': 'notifications/message',
      'params': {
        'level': 'warning',
        'logger': 'cache',
        'data': 'Cache capacity reached 90%',
      },
    });

    await tester.pumpWidget(wrapWithTheme(session, state));
    await tester.pumpAndSettle();

    // Verify terminal log lines
    expect(find.text('No server logs yet'), findsNothing);
    expect(find.textContaining('Failed to connect to database at localhost:5432'), findsOneWidget);
    expect(find.textContaining('Connection pool initialized with 5 workers'), findsOneWidget);
    expect(find.textContaining('Cache capacity reached 90%'), findsOneWidget);
    expect(find.text('STDERR'), findsAtLeastNWidgets(1));
    expect(find.text('INFO'), findsAtLeastNWidgets(1));
    expect(find.text('WARN'), findsAtLeastNWidgets(1));
    expect(find.textContaining('[db-pool]'), findsOneWidget);
    expect(find.textContaining('[cache]'), findsOneWidget);
    expect(find.byType(SelectableText), findsNWidgets(3));

    // Filter by category: ERROR / STDERR
    await tester.tap(find.text('STDERR').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Failed to connect to database at localhost:5432'), findsOneWidget);
    expect(find.textContaining('Connection pool initialized with 5 workers'), findsNothing);

    // Filter back to ALL
    await tester.tap(find.text('ALL').first);
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsNWidgets(3));

    // Filter by text search
    await tester.enterText(find.byType(EditableText).first, 'pool');
    await tester.pumpAndSettle();
    expect(find.textContaining('Connection pool initialized with 5 workers'), findsOneWidget);
    expect(find.textContaining('Cache capacity reached 90%'), findsNothing);

    // Clear filter
    await tester.enterText(find.byType(EditableText).first, '');
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsNWidgets(3));

    // Clear logs button
    expect(find.text('Clear'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('No server logs yet'), findsOneWidget);
  });
}
