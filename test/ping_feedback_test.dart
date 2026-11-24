import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Material;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';
import 'package:rocket_mcp/features/workspace/server_header.dart';
import 'package:rocket_mcp/theme/theme.dart';

void main() {
  testWidgets('Pinging a connected server gives toast feedback and visual in-flight state', (tester) async {
    final state = AppState();
    final config = const McpServerConfig(
      id: 'test_server',
      name: 'Ping Test Server',
      command: 'echo',
    );

    String? lastToast;

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
              'serverInfo': {'name': 'Mock Server', 'version': '1.0.0'},
              'capabilities': {},
            },
          };
        }
        if (method == 'ping') {
          return {'jsonrpc': '2.0', 'id': id, 'result': {}};
        }
        return {'jsonrpc': '2.0', 'id': id, 'result': {}};
      },
    );

    final session = McpSession(
      config: config,
      transportOverride: transport,
      onToast: (msg) => lastToast = msg,
    );

    await session.connect();

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: PalScope(
          pal: DarkPal,
          child: MaterialApp(
            home: Material(
              child: ServerHeader(
                state: state,
                server: config,
                session: session,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial Ping button
    expect(find.widgetWithText(Btn, 'Ping'), findsOneWidget);

    // Tap Ping button
    await tester.tap(find.widgetWithText(Btn, 'Ping'));
    await tester.pump(); // Start ping

    // Verify feedback toast received
    expect(lastToast, isNotNull);
    expect(lastToast, contains('Ping "Ping Test Server"'));

    await tester.pumpAndSettle();

    // Verify Ping button returned to normal
    expect(find.widgetWithText(Btn, 'Ping'), findsOneWidget);
    expect(session.pingLatency, isNotNull);
  });

  testWidgets('Pinging when disconnected gives feedback', (tester) async {
    final config = const McpServerConfig(
      id: 'disc_server',
      name: 'Disconnected Server',
      command: 'echo',
    );

    String? toast;
    final session = McpSession(
      config: config,
      onToast: (msg) => toast = msg,
    );

    await session.ping(feedback: true);
    expect(toast, 'Server "Disconnected Server" is not connected');
  });
}
