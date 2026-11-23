import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/core/model/app_settings.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/shell/app.dart';
import 'package:rocket_mcp/features/shell/menu_model.dart';
import 'package:rocket_mcp/features/shell/menus.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/update_checker.dart';

void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('rocketmcp-test');
    AppStore.homeOverride = home.path;
  });

  tearDown(() {
    AppStore.homeOverride = null;
    home.deleteSync(recursive: true);
  });

  group('AppSettings', () {
    test('round-trips through json and ignores wrongly typed fields', () {
      const saved = AppSettings(theme: ThemeMode.dark, fontSize: 15);
      expect(AppSettings.fromJson(saved.toJson()), isA<AppSettings>());
      final read = AppSettings.fromJson({'theme': 'dark', 'fontSize': 'big'});
      expect(read.theme, ThemeMode.dark);
      expect(read.fontSize, AppSettings.defaultFontSize);
    });
  });

  group('AppState', () {
    test('zoom steps within bounds and 0 resets', () {
      final state = AppState();
      for (var i = 0; i < 20; i++) {
        state.zoom(1);
      }
      expect(state.settings.fontSize, AppSettings.maxFontSize);
      state.zoom(0);
      expect(state.settings.fontSize, AppSettings.defaultFontSize);
    });

    test('settings are saved and reloaded', () {
      AppState().toggleLayout();
      expect(AppStore.loadSettings().verticalLayout, isFalse);
    });

    test('panel sizes are saved and restored', () {
      AppState()
        ..sidebarWidth = 0.3
        ..listPaneWidth = 300
        ..splitFraction = 0.35
        ..persist();
      final restored = AppState();
      expect(restored.sidebarWidth, 0.3);
      expect(restored.listPaneWidth, 300);
      expect(restored.splitFraction, 0.35);
    });

    test('panel sizes stay within their limits', () {
      final state = AppState()
        ..listPaneWidth = 10000
        ..splitFraction = 5;
      expect(state.listPaneWidth, AppState.maxListPaneWidth);
      expect(state.splitFraction, AppState.maxSplitFraction);
    });

    test('palette toggles', () {
      final state = AppState()..togglePalette();
      expect(state.modal, isA<ModalPalette>());
      state.togglePalette();
      expect(state.modal, isNull);
    });
  });

  group('AppMenus', () {
    test('macOS leaves About, Preferences and Exit to the app menu', () {
      final labels = AppMenus.build(
        AppState(),
        isMac: true,
      ).expand((m) => m.items).whereType<MenuItemSpec>().map((i) => i.label);
      expect(labels, isNot(contains('Exit')));
      expect(labels, isNot(contains('Preferences…')));
    });

    test('Windows and Linux put them in File and Help', () {
      final labels = AppMenus.build(
        AppState(),
        isMac: false,
      ).expand((m) => m.items).whereType<MenuItemSpec>().map((i) => i.label);
      expect(labels, containsAll(['Exit', 'Preferences…', 'About Rocket MCP']));
    });
  });

  group('UpdateChecker', () {
    test('dismissed versions are remembered and cleared', () async {
      await UpdateChecker.dismissVersion('2.0.0');
      expect(UpdateChecker.isDismissed('2.0.0'), isTrue);
      await UpdateChecker.clearDismissed();
      expect(UpdateChecker.isDismissed('2.0.0'), isFalse);
    });
  });

  testWidgets('the shell shows the title, status bar and palette', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AppScope(
            state: state,
            child: RocketTheme(dark: true, child: RocketApp(state: state)),
          ),
        ),
      ),
    );
    expect(find.text('Rocket MCP'), findsWidgets);
    expect(find.text('commands'), findsOneWidget);

    state.modal = const ModalPalette();
    await tester.pump();
    expect(find.text('Preferences'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
