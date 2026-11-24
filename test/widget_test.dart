import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';
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
      const saved = AppSettings(
        theme: ThemeMode.dark,
        fontSize: 15,
        autoConnect: true,
      );
      final json = saved.toJson();
      expect(json['autoConnect'], isTrue);
      final revived = AppSettings.fromJson(json);
      expect(revived.autoConnect, isTrue);
      final read = AppSettings.fromJson({
        'theme': 'dark',
        'fontSize': 'big',
        'autoConnect': 'yes',
      });
      expect(read.theme, ThemeMode.dark);
      expect(read.fontSize, AppSettings.defaultFontSize);
      expect(read.autoConnect, isFalse);
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

    test('selected server is preserved on restart and auto-connects when enabled', () async {
      const s1 = McpServerConfig(id: 's1', name: 'Server 1', command: 'echo');
      const s2 = McpServerConfig(id: 's2', name: 'Server 2', command: 'echo');
      final connected = <String>[];

      McpTransport mockTransport(McpServerConfig s) => McpInMemoryTransport(
        onRequest: (msg) {
          if (msg['method'] == 'initialize') {
            connected.add(s.id);
            return {
              'jsonrpc': '2.0',
              'id': msg['id'],
              'result': {
                'protocolVersion': '2024-11-05',
                'serverInfo': {'name': s.name, 'version': '1.0.0'},
                'capabilities': {},
              },
            };
          }
          return {'jsonrpc': '2.0', 'id': msg['id'], 'result': {}};
        },
      );

      // 1. Initial run: default active is s1, select s2
      final app1 = AppState(
        initialServers: [s1, s2],
        transportFactory: mockTransport,
      );
      expect(app1.activeServerId, 's1');
      app1.selectServer('s2');
      expect(app1.activeServerId, 's2');
      app1.updateSettings(app1.settings.copyWith(autoConnect: true));

      // 2. Restart app: s2 should be restored as selected server and auto-connected
      connected.clear();
      final app2 = AppState(
        initialServers: [s1, s2],
        transportFactory: mockTransport,
      );
      expect(app2.activeServerId, 's2');
      await pumpEventQueue();

      // Only the selected server s2 should have been auto-connected, s1 remains disconnected
      expect(connected, contains('s2'));
      expect(connected, isNot(contains('s1')));
      expect(app2.getSession('s2')?.status, McpServerStatus.connected);
      expect(app2.getSession('s1')?.status, McpServerStatus.disconnected);

      // Clean up settings
      app2.updateSettings(app2.settings.copyWith(autoConnect: false));
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

    test('Includes standard Edit and View menus with shortcuts', () {
      final menus = AppMenus.build(AppState(), isMac: true);
      final menuNames = menus.map((m) => m.label).toList();
      expect(
        menuNames,
        containsAll(['File', 'Edit', 'View', 'Server', 'Window', 'Help']),
      );

      final editItems = menus
          .firstWhere((m) => m.label == 'Edit')
          .items
          .whereType<MenuItemSpec>()
          .map((i) => i.label)
          .toList();
      expect(
        editItems,
        containsAll(['Undo', 'Redo', 'Cut', 'Copy', 'Paste', 'Select All']),
      );

      final viewSubmenus = menus
          .firstWhere((m) => m.label == 'View')
          .items
          .whereType<SubMenuSpec>()
          .map((s) => s.label)
          .toList();
      expect(viewSubmenus, contains('Switch Workspace Tab'));
    });

    test('Shortcut labels adapt appropriately for Mac and Windows/Linux', () {
      const undoMac = Shortcut(LogicalKeyboardKey.keyZ);
      expect(undoMac.label(true), '⌘Z');
      expect(undoMac.label(false), 'Ctrl+Z');

      const redoWin = Shortcut(LogicalKeyboardKey.keyY);
      expect(redoWin.label(false), 'Ctrl+Y');

      const tabSwitch = Shortcut(LogicalKeyboardKey.digit1);
      expect(tabSwitch.label(true), '⌘1');
      expect(tabSwitch.label(false), 'Ctrl+1');

      const helpWin = Shortcut(LogicalKeyboardKey.f1, primary: false);
      expect(helpWin.label(false), 'F1');
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
