import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Material;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/code_view.dart';
import 'package:rocket_mcp/components/response_controls.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';
import 'package:rocket_mcp/features/workspace/response_viewer.dart';
import 'package:rocket_mcp/theme/theme.dart';

void main() {
  testWidgets('ResponseViewer defaults to Formatted view mode', (tester) async {
    final state = AppState();
    final config = const McpServerConfig(
      id: 'test_server',
      name: 'Test Server',
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
              'serverInfo': {'name': 'Mock Server', 'version': '1.0.0'},
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
                  'name': 'echo',
                  'description': 'Echoes message',
                  'inputSchema': {
                    'type': 'object',
                    'properties': {
                      'message': {'type': 'string'},
                    },
                  },
                },
              ],
            },
          };
        }
        if (method == 'tools/call') {
          return {
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'content': [
                {'type': 'text', 'text': 'Hello, formatted response!'},
              ],
              'isError': false,
            },
          };
        }
        return {'jsonrpc': '2.0', 'id': id, 'result': {}};
      },
    );

    final session = McpSession(
      config: config,
      transportOverride: transport,
    );

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: PalScope(
          pal: DarkPal,
          child: MaterialApp(
            home: Material(
              child: ResponseViewer(
                session: session,
                onToggleLayout: () {},
                isVertical: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No response yet'), findsOneWidget);

    // Connect session and execute tool
    await session.connect();
    await tester.pumpAndSettle();

    expect(session.tools.length, 1);
    session.selectedTool = session.tools.first;
    await session.executeTool();

    await tester.pumpAndSettle();

    // Check that ViewModeMenu shows 'Formatted' by default
    final menu = tester.widget<ViewModeMenu>(find.byType(ViewModeMenu));
    expect(menu.current, 'Formatted');

    // CodeView should be rendered with formatted text
    expect(find.byType(CodeView), findsOneWidget);
    expect(find.textContaining('Hello, formatted response!'), findsOneWidget);
  });
}
