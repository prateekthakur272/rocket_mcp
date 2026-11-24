import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
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
    VoidCallback? toggleMaximize,
  }) {
    Shortcut key(
      LogicalKeyboardKey k, {
      bool primary = true,
      bool shift = false,
      bool control = false,
      bool alt = false,
    }) =>
        Shortcut(k, primary: primary, shift: shift, control: control, alt: alt);

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

    void invokeTextIntent(Intent intent) {
      final primaryContext = primaryFocus?.context;
      if (primaryContext != null) {
        Actions.maybeInvoke(primaryContext, intent);
      }
    }

    final settings = state.settings;

    final file = MenuSpec('File', [
      item(
        'New Server…',
        () => state.modal = const ModalServerConfig(),
        shortcut: key(LogicalKeyboardKey.keyN),
      ),
      item(
        'Server Template Gallery…',
        () => state.modal = const ModalTemplateGallery(),
        shortcut: key(LogicalKeyboardKey.keyT),
      ),
      item(
        'Import / Export Servers…',
        () => state.modal = const ModalImportExport(),
        shortcut: key(LogicalKeyboardKey.keyI, shift: true),
      ),
      item(
        'Open Storage Folder',
        () => Platform.reveal(AppStore.dir),
        shortcut: key(LogicalKeyboardKey.keyO, shift: true),
      ),
      const MenuSeparator(),
      item('Close Window', () {
        if (state.modal != null) {
          state.modal = null;
        } else {
          quit?.call();
        }
      }, shortcut: key(LogicalKeyboardKey.keyW)),
      if (!isMac) ...[
        const MenuSeparator(),
        item(
          'Preferences…',
          () => state.modal = const ModalSettings(),
          shortcut: key(LogicalKeyboardKey.comma),
        ),
        const MenuSeparator(),
        item('Exit', quit ?? () {}, shortcut: key(LogicalKeyboardKey.keyQ)),
      ],
    ]);

    final edit = MenuSpec('Edit', [
      item(
        'Undo',
        () => invokeTextIntent(
          const UndoTextIntent(SelectionChangedCause.keyboard),
        ),
        shortcut: key(LogicalKeyboardKey.keyZ),
      ),
      item(
        'Redo',
        () => invokeTextIntent(
          const RedoTextIntent(SelectionChangedCause.keyboard),
        ),
        shortcut: isMac
            ? key(LogicalKeyboardKey.keyZ, shift: true)
            : key(LogicalKeyboardKey.keyY),
      ),
      const MenuSeparator(),
      item(
        'Cut',
        () => invokeTextIntent(
          const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
        ),
        shortcut: key(LogicalKeyboardKey.keyX),
      ),
      item(
        'Copy',
        () => invokeTextIntent(CopySelectionTextIntent.copy),
        shortcut: key(LogicalKeyboardKey.keyC),
      ),
      item(
        'Paste',
        () => invokeTextIntent(
          const PasteTextIntent(SelectionChangedCause.keyboard),
        ),
        shortcut: key(LogicalKeyboardKey.keyV),
      ),
      item(
        'Select All',
        () => invokeTextIntent(
          const SelectAllTextIntent(SelectionChangedCause.keyboard),
        ),
        shortcut: key(LogicalKeyboardKey.keyA),
      ),
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
      const MenuSeparator(),
      SubMenuSpec('Switch Workspace Tab', [
        item(
          'Tools',
          () => state.activeSession?.activeTab = WorkspaceTab.tools,
          shortcut: key(LogicalKeyboardKey.digit1),
          enabled: state.activeSession != null,
        ),
        item(
          'Resources',
          () => state.activeSession?.activeTab = WorkspaceTab.resources,
          shortcut: key(LogicalKeyboardKey.digit2),
          enabled: state.activeSession != null,
        ),
        item(
          'Prompts',
          () => state.activeSession?.activeTab = WorkspaceTab.prompts,
          shortcut: key(LogicalKeyboardKey.digit3),
          enabled: state.activeSession != null,
        ),
        item(
          'Traffic Inspector',
          () => state.activeSession?.activeTab = WorkspaceTab.inspector,
          shortcut: key(LogicalKeyboardKey.digit4),
          enabled: state.activeSession != null,
        ),
        item(
          'Server Logs',
          () => state.activeSession?.activeTab = WorkspaceTab.logs,
          shortcut: key(LogicalKeyboardKey.digit5),
          enabled: state.activeSession != null,
        ),
        item(
          'Raw JSON-RPC',
          () => state.activeSession?.activeTab = WorkspaceTab.raw,
          shortcut: key(LogicalKeyboardKey.digit6),
          enabled: state.activeSession != null,
        ),
      ]),
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

    final serverMenu = MenuSpec('Server', [
      item(
        'Connect / Reconnect Active Server',
        () => state.activeSession?.connect(),
        shortcut: key(LogicalKeyboardKey.keyR),
        enabled: state.activeSession != null,
      ),
      item(
        'Disconnect Active Server',
        () => state.activeSession?.disconnect(),
        shortcut: key(LogicalKeyboardKey.keyD, shift: true),
        enabled:
            state.activeSession != null &&
            state.activeSession?.status == McpServerStatus.connected,
      ),
      item(
        'Refresh Capabilities',
        () => state.activeSession?.discover(),
        shortcut: key(LogicalKeyboardKey.keyR, shift: true),
        enabled:
            state.activeSession != null &&
            state.activeSession?.status == McpServerStatus.connected,
      ),
      item(
        'Ping Server',
        () => state.activeSession?.ping(feedback: true),
        shortcut: key(LogicalKeyboardKey.keyP, shift: true),
        enabled:
            state.activeSession != null &&
            state.activeSession?.status == McpServerStatus.connected,
      ),
      const MenuSeparator(),
      item(
        'Next Server',
        () {
          final servers = state.servers;
          if (servers.length <= 1) return;
          final idx = servers.indexWhere((s) => s.id == state.activeServerId);
          final next = (idx + 1) % servers.length;
          state.selectServer(servers[next].id);
        },
        shortcut: key(LogicalKeyboardKey.bracketRight),
        enabled: state.servers.length > 1,
      ),
      item(
        'Previous Server',
        () {
          final servers = state.servers;
          if (servers.length <= 1) return;
          final idx = servers.indexWhere((s) => s.id == state.activeServerId);
          final prev = (idx - 1 + servers.length) % servers.length;
          state.selectServer(servers[prev].id);
        },
        shortcut: key(LogicalKeyboardKey.bracketLeft),
        enabled: state.servers.length > 1,
      ),
      const MenuSeparator(),
      item('Server Configuration…', () {
        if (state.activeServer != null) {
          state.modal = ModalServerConfig(server: state.activeServer);
        }
      }, enabled: state.activeServer != null),
    ]);

    final window = MenuSpec('Window', [
      item(
        'Minimize',
        minimize ?? () {},
        shortcut: isMac
            ? key(LogicalKeyboardKey.keyM)
            : key(LogicalKeyboardKey.keyM, primary: false, alt: true),
      ),
      item('Zoom / Maximize', toggleMaximize ?? () {}),
      const MenuSeparator(),
      item('Next Tab', () {
        final s = state.activeSession;
        if (s != null) {
          final tabs = WorkspaceTab.values;
          s.activeTab = tabs[(tabs.indexOf(s.activeTab) + 1) % tabs.length];
        }
      }, shortcut: key(LogicalKeyboardKey.tab, primary: false, control: true)),
      item(
        'Previous Tab',
        () {
          final s = state.activeSession;
          if (s != null) {
            final tabs = WorkspaceTab.values;
            s.activeTab =
                tabs[(tabs.indexOf(s.activeTab) - 1 + tabs.length) %
                    tabs.length];
          }
        },
        shortcut: key(
          LogicalKeyboardKey.tab,
          primary: false,
          control: true,
          shift: true,
        ),
      ),
    ]);

    final help = MenuSpec('Help', [
      item(
        'Welcome & Onboarding Tour…',
        () => state.modal = const ModalOnboarding(),
      ),
      item(
        'Keyboard Shortcuts',
        () {
          state.prefsSection = 'Shortcuts';
          state.modal = const ModalSettings();
        },
        shortcut: isMac
            ? key(LogicalKeyboardKey.slash)
            : key(LogicalKeyboardKey.f1, primary: false),
      ),
      item(
        'Documentation',
        () => Platform.openUrl('https://modelcontextprotocol.io'),
      ),
      item(
        'Report an Issue',
        () => Platform.openUrl(IssueReport.url().toString()),
      ),
      item('Developer Tools…', () => state.modal = const ModalDeveloper()),
      const MenuSeparator(),
      item('Check for Updates…', () => checkForUpdates(state)),
      if (!isMac) ...[
        const MenuSeparator(),
        item('About ${AppConfig.NAME}', () => state.modal = const ModalAbout()),
      ],
    ]);

    return [file, edit, view, serverMenu, window, help];
  }
}
