import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Material;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/templates/server_template_model.dart';
import 'package:rocket_mcp/features/templates/template_gallery_dialog.dart';
import 'package:rocket_mcp/theme/theme.dart';

void main() {
  late Directory tempHome;

  setUp(() {
    tempHome = Directory.systemTemp.createTempSync('rocketmcp-templates-test');
    AppStore.homeOverride = tempHome.path;
  });

  tearDown(() {
    AppStore.homeOverride = null;
    tempHome.deleteSync(recursive: true);
  });

  testWidgets('TemplateGalleryDialog displays templates and handles search & filters', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = AppState();
    state.modal = const ModalTemplateGallery();

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: PalScope(
          pal: DarkPal,
          child: MaterialApp(
            home: Material(
              child: TemplateGalleryDialog(state: state),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dialog header and categories
    expect(find.text('Server Template Gallery'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Reference & Test'), findsOneWidget);
    expect(find.text('Databases & Storage'), findsOneWidget);
    expect(find.text('Developer Tools'), findsOneWidget);
    expect(find.text('Web & Automation'), findsOneWidget);
    expect(find.text('Productivity & Cloud'), findsOneWidget);

    // Initial templates visible
    expect(find.text('Everything Server'), findsOneWidget);
    expect(find.text('Memory Knowledge Graph'), findsOneWidget);

    // Filter by Databases category
    await tester.tap(find.text('Databases & Storage'));
    await tester.pumpAndSettle();

    expect(find.text('Local Filesystem'), findsOneWidget);
    expect(find.text('SQLite Database'), findsOneWidget);
    expect(find.text('Everything Server'), findsNothing);

    // Search by text query
    await tester.enterText(find.byType(EditableText).first, 'sqlite');
    await tester.pumpAndSettle();

    expect(find.text('SQLite Database'), findsOneWidget);
    expect(find.text('Local Filesystem'), findsNothing);

    // Add SQLite Server
    final addBtn = find.text('Add Server').first;
    await tester.tap(addBtn);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    // Modal closed and server added to workspace
    expect(state.modal, isNull);
    expect(state.servers.any((s) => s.name.contains('SQLite Server')), isTrue);
  });

  testWidgets('TemplateGalleryDialog customize button opens ModalServerConfig', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = AppState();
    state.modal = const ModalTemplateGallery();

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: PalScope(
          pal: DarkPal,
          child: MaterialApp(
            home: Material(
              child: TemplateGalleryDialog(state: state),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Customize on the first template
    final customizeBtn = find.text('Customize…').first;
    await tester.tap(customizeBtn);
    await tester.pumpAndSettle();

    // Modal switched to ModalServerConfig with pre-filled template
    expect(state.modal, isA<ModalServerConfig>());
    final modalConfig = state.modal as ModalServerConfig;
    expect(modalConfig.server?.name, ServerTemplates.all.first.name);
  });
}
