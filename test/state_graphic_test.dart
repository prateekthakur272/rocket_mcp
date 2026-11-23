import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/components/state_graphic.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/workspace/disconnected_panel.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

Widget _host(Widget child) => MaterialApp(
  home: Material(child: RocketTheme(dark: false, child: child)),
);

void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('rocketmcp-graphic-test');
    AppStore.homeOverride = home.path;
  });

  tearDown(() {
    AppStore.homeOverride = null;
    home.deleteSync(recursive: true);
  });

  testWidgets('StateGraphic renders all graphic types cleanly', (tester) async {
    for (final type in StateGraphicType.values) {
      await tester.pumpWidget(_host(StateGraphic(type: type)));
      expect(find.byType(StateGraphic), findsOneWidget);
    }
  });

  testWidgets(
    'EmptyState automatically renders StateGraphic when icon is provided',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const EmptyState(
            icon: Ic.disconnect,
            title: 'Not connected',
            message: 'Connect to server',
          ),
        ),
      );
      expect(find.byType(StateGraphic), findsOneWidget);
      expect(find.text('Not connected'), findsOneWidget);
      expect(find.text('Connect to server'), findsOneWidget);
    },
  );

  testWidgets(
    'EmptyState does not render graphic when neither graphic nor icon is provided',
    (tester) async {
      await tester.pumpWidget(
        _host(const EmptyState(title: 'No response yet')),
      );
      expect(find.byType(StateGraphic), findsNothing);
      expect(find.text('No response yet'), findsOneWidget);
    },
  );

  testWidgets(
    'DisconnectedPanel renders rich graphic in disconnected and error states',
    (tester) async {
      final state = AppState();
      const server = McpServerConfig(id: 'test', name: 'Test Server');
      final session = McpSession(config: server);

      await tester.pumpWidget(
        _host(
          DisconnectedPanel(state: state, server: server, session: session),
        ),
      );
      expect(find.byType(StateGraphic), findsOneWidget);
      expect(find.text('Not connected'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Configurations'), findsOneWidget);
    },
  );
}
