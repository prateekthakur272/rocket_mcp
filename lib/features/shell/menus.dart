import 'package:flutter/services.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/core/model/app_settings.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/shell/menu_model.dart';
import 'package:rocket_mcp/features/shell/update_dialog.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/utils/app_config.dart';
import 'package:rocket_mcp/utils/issue_report.dart';

/// The application menu bar as plain data, so one definition serves both renderers: macOS turns it into the native
/// menu bar (`main.dart`) and Windows / Linux draw it inside the title bar (`TitleMenus`).
///
/// macOS keeps About, Preferences and Quit in the application menu (added by `main.dart`), so they are left out here.
/// Windows / Linux: Preferences and Exit are in File and About is in Help; shortcuts use Ctrl instead of ⌘.
/// To add a menu item, add it here and nowhere else.
class AppMenus {
  const AppMenus._();

  static List<MenuSpec> build(
    AppState state, {
    required bool isMac,
    VoidCallback? quit,
    VoidCallback? minimize,
  }) {
    Shortcut key(LogicalKeyboardKey k, {bool shift = false}) =>
        Shortcut(k, shift: shift);
    MenuItemSpec item(
      String label,
      VoidCallback action, {
      Shortcut? shortcut,
      bool enabled = true,
    }) => MenuItemSpec(
      label,
      shortcut: shortcut,
      enabled: enabled,
      action: action,
    );
    MenuItemSpec check(
      String label,
      bool checked,
      VoidCallback action, {
      Shortcut? shortcut,
    }) => MenuItemSpec(
      label,
      shortcut: shortcut,
      checked: checked,
      action: action,
    );

    final settings = state.settings;

    final file = MenuSpec('File', [
      if (!isMac) ...[
        item(
          'Preferences…',
          () => state.modal = const ModalSettings(),
          shortcut: key(LogicalKeyboardKey.comma),
        ),
        const MenuSeparator(),
        item('Exit', quit ?? () {}, shortcut: key(LogicalKeyboardKey.keyQ)),
      ] else
        item('Show Data Folder', () => Platform.reveal(AppStore.dir)),
    ]);

    final view = MenuSpec('View', [
      item(
        'Command Palette…',
        state.togglePalette,
        shortcut: key(LogicalKeyboardKey.keyK),
      ),
      const MenuSeparator(),
      check(
        'Show Sidebar',
        state.sidebarVisible,
        () => state.sidebarVisible = !state.sidebarVisible,
        shortcut: key(LogicalKeyboardKey.keyB),
      ),
      check(
        'Stack Request Above Response',
        settings.verticalLayout,
        state.toggleLayout,
        shortcut: key(LogicalKeyboardKey.keyL, shift: true),
      ),
      SubMenuSpec('Theme', [
        for (final mode in ThemeMode.values)
          check(
            mode.label,
            settings.theme == mode,
            () => state.updateSettings(settings.copyWith(theme: mode)),
          ),
      ]),
      const MenuSeparator(),
      item(
        'Zoom In',
        () => state.zoom(1),
        shortcut: key(LogicalKeyboardKey.equal),
        enabled: settings.fontSize < AppSettings.maxFontSize,
      ),
      item(
        'Zoom Out',
        () => state.zoom(-1),
        shortcut: key(LogicalKeyboardKey.minus),
        enabled: settings.fontSize > AppSettings.minFontSize,
      ),
      item(
        'Actual Size',
        () => state.zoom(0),
        shortcut: key(LogicalKeyboardKey.digit0),
        enabled: settings.fontSize != AppSettings.defaultFontSize,
      ),
    ]);

    final window = MenuSpec('Window', [
      item(
        'Minimize',
        minimize ?? () {},
        shortcut: isMac ? key(LogicalKeyboardKey.keyM) : null,
      ),
    ]);

    final help = MenuSpec('Help', [
      item('Keyboard Shortcuts', () {
        state.prefsSection = 'Shortcuts';
        state.modal = const ModalSettings();
      }),
      item('Developer…', () => state.modal = const ModalDeveloper()),
      item(
        'Report an Issue',
        () => Platform.openUrl(IssueReport.url().toString()),
      ),
      const MenuSeparator(),
      item('Check for Updates…', () => checkForUpdates(state)),
      if (!isMac) ...[
        const MenuSeparator(),
        item('About ${AppConfig.NAME}', () => state.modal = const ModalAbout()),
      ],
    ]);

    return [file, view, window, help];
  }
}
