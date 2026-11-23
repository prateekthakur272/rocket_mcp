import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/workspace/resource_runner_view.dart';
import 'package:rocket_mcp/theme/theme.dart';

Widget _host(AppState state, Widget child) => AppScope(
  state: state,
  child: MaterialApp(
    home: Material(child: RocketTheme(dark: false, child: child)),
  ),
);

void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('rocketmcp-resource-test');
    AppStore.homeOverride = home.path;
  });

  tearDown(() {
    AppStore.homeOverride = null;
    home.deleteSync(recursive: true);
  });

  testWidgets(
    'ResourceRunnerView displays template parameters and updates resolved URI live',
    (tester) async {
      final state = AppState();
      final session = McpSession(
        config: const McpServerConfig(id: 'test', name: 'Test Server'),
      );

      // Add a resource template
      session.resourceTemplates.add(
        const McpResourceTemplate(
          name: 'Dynamic Blob',
          uriTemplate: 'demo://resource/dynamic/blob/{resourceId}',
          description: 'Fetches dynamic blob resource by ID',
        ),
      );

      await tester.pumpWidget(
        _host(state, ResourceRunnerView(session: session)),
      );
      await tester.pumpAndSettle();

      // Verify template appears in list
      expect(find.text('Dynamic Blob'), findsOneWidget);

      // Tap on template
      await tester.tap(find.text('Dynamic Blob'));
      await tester.pumpAndSettle();

      // Verify parameters section header appeared
      expect(find.text('TEMPLATE PARAMETERS'), findsOneWidget);
      expect(find.text('0/1 filled'), findsOneWidget);
      expect(find.text('{resourceId}'), findsOneWidget);
      expect(find.text('PATH'), findsOneWidget);

      // Find the parameter field (the second field after the sidebar filter)
      final fields = find.byType(Field);
      expect(fields, findsNWidgets(2)); // 1 for filter, 1 for resourceId
      final paramField = fields.at(1);

      // Type "42" into parameter field
      await tester.enterText(paramField, '42');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify parameter is filled and URI is resolved
      expect(find.text('All 1 filled'), findsOneWidget);
      expect(find.text('demo://resource/dynamic/blob/42'), findsWidgets);
    },
  );

  testWidgets(
    'ResourceRunnerView filters resources and templates by search query',
    (tester) async {
      final state = AppState();
      final session = McpSession(
        config: const McpServerConfig(id: 'test', name: 'Test Server'),
      );

      session.resources.add(
        const McpResource(uri: 'file:///docs/readme.md', name: 'Static Readme'),
      );
      session.resourceTemplates.add(
        const McpResourceTemplate(
          name: 'Dynamic Search',
          uriTemplate: 'search://items{?query}',
        ),
      );

      await tester.pumpWidget(
        _host(state, ResourceRunnerView(session: session)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Static Readme'), findsOneWidget);
      expect(find.text('Dynamic Search'), findsOneWidget);

      // Type "search" into the filter field
      final filterField = find.byType(Field).first;
      await tester.enterText(filterField, 'search');
      await tester.pumpAndSettle();

      // Only Dynamic Search should match
      expect(find.text('Dynamic Search'), findsOneWidget);
      expect(find.text('Static Readme'), findsNothing);
    },
  );
}
