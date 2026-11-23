// ignore_for_file: constant_identifier_names, non_constant_identifier_names, deprecated_member_use
import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart' hide Chip, ThemeMode;
import 'package:rocket_mcp/utils/app_config.dart';
import 'package:rocket_mcp/utils/app_metadata.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/core/logging/log.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/shell/app.dart';
import 'package:rocket_mcp/features/shell/key_handler.dart';
import 'package:rocket_mcp/features/shell/menu_model.dart';
import 'package:rocket_mcp/features/shell/menus.dart';
import 'package:rocket_mcp/features/shell/update_dialog.dart';
import 'package:rocket_mcp/features/shell/window_chrome.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:window_manager/legacy.dart' as wm;

/// True when the saved window would still show a usable part of a connected screen (a monitor may have been unplugged since).
/// Display origins aren't exposed, so this accepts a point within one screen-width either side of the primary display.
bool _onScreen(double x, double y, double w, double h) {
  try {
    final probe = Offset(x + 40, y + 20); // a point inside the title bar area
    for (final d in PlatformDispatcher.instance.displays) {
      final dw = d.size.width / d.devicePixelRatio;
      final dh = d.size.height / d.devicePixelRatio;
      if (probe.dx > -dw &&
          probe.dx < 2 * dw &&
          probe.dy >= -dh &&
          probe.dy < 2 * dh) {
        return true;
      }
    }
  } catch (_) {}
  return false;
}

bool _positionVisible(WindowGeometry? g) =>
    g != null &&
    g.x != null &&
    g.y != null &&
    _onScreen(g.x!, g.y!, g.width, g.height);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppMetadata.load();
  final isMac = Platform.isMac;
  await wm.windowManager.ensureInitialized();
  // The app's own top bar is the title bar. macOS keeps its native traffic-light buttons, floating over that bar;
  // Windows / Linux draw nothing, so the app supplies its own window buttons, drag area and resize edges.
  // Reopen where the user left it; a saved position that is no longer on any screen is dropped.
  final saved = AppStore.loadWindow();
  final placed = _positionVisible(saved);
  await wm.windowManager.waitUntilReadyToShow(
    wm.WindowOptions(
      size: saved != null
          ? Size(saved.width, saved.height)
          : const Size(1360, 860),
      minimumSize: const Size(760, 480),
      center: !placed,
      title: AppConfig.NAME,
      titleBarStyle: wm.TitleBarStyle.hidden,
      windowButtonVisibility: isMac,
    ),
    () async {
      if (saved != null && placed) {
        await wm.windowManager.setPosition(Offset(saved.x!, saved.y!));
      }
      if (saved != null && saved.maximized) await wm.windowManager.maximize();
      // Shown from the first rendered frame (below) so there is no empty black window while the engine starts.
    },
  );
  await wm.windowManager.setPreventClose(true);
  runApp(const RocketRoot());
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await wm.windowManager.setOpacity(1);
    await wm.windowManager.show();
    await wm.windowManager.focus();
  });
}

/// Desktop scroll behaviour: no automatic scrollbars, no bounce / glow overscroll.
class _DesktopScrollBehavior extends MaterialScrollBehavior {
  const _DesktopScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

class RocketRoot extends StatefulWidget {
  const RocketRoot({super.key});

  @override
  State<RocketRoot> createState() => _RocketRootState();
}

class _RocketRootState extends State<RocketRoot>
    with WidgetsBindingObserver, wm.WindowListener {
  late final AppState state;
  bool maximized = false;
  late bool dark;

  bool get isMac => Platform.isMac;

  bool _computeDark() => state.settings.theme.isDark(
    WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
  );

  @override
  void initState() {
    super.initState();
    state = AppState();
    dark = _computeDark();
    state.addListener(_onState);
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    wm.windowManager.addListener(this);
    // Check for a newer GitHub release after the first frame so it never
    // delays startup. The result is shown only when the user is not already
    // looking at a dialog.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(checkForUpdateAtStartup(state)),
    );
  }

  @override
  void dispose() {
    _boundsTimer?.cancel();
    wm.windowManager.removeListener(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    WidgetsBinding.instance.removeObserver(this);
    state.removeListener(_onState);
    super.dispose();
  }

  Timer? _boundsTimer;

  /// The floating size / position is kept while maximized, so un-maximizing returns to it.
  WindowGeometry? _floating = AppStore.loadWindow();

  /// Remember the window's size and position shortly after the user stops moving or resizing it.
  void _saveBoundsSoon() {
    _boundsTimer?.cancel();
    _boundsTimer = Timer(const Duration(milliseconds: 400), _saveBounds);
  }

  Future<void> _saveBounds() async {
    try {
      final max = await wm.windowManager.isMaximized();
      if (!max &&
          !await wm.windowManager.isFullScreen() &&
          !await wm.windowManager.isMinimized()) {
        final r = await wm.windowManager.getBounds();
        _floating = WindowGeometry(r.width, r.height, r.left, r.top);
      }
      final f = _floating;
      if (f != null) AppStore.saveWindow(f.copyWith(maximized: max));
    } catch (e, st) {
      Log.warning('window', 'Cannot save the window geometry', e, st);
    }
  }

  @override
  void onWindowResized() => _saveBoundsSoon();

  @override
  void onWindowMoved() => _saveBoundsSoon();

  void _onState() {
    final d = _computeDark();
    if (d != dark) setState(() => dark = d);
  }

  @override
  void didChangePlatformBrightness() => _onState();

  bool _onKey(KeyEvent e) {
    if (e is KeyDownEvent &&
        !isMac &&
        HardwareKeyboard.instance.isControlPressed &&
        e.logicalKey == LogicalKeyboardKey.keyQ) {
      quit();
      return true;
    }
    return handleKey(state, e);
  }

  /// Persist and leave (also what the window's close button and Cmd/Ctrl+Q do).
  void quit() {
    _boundsTimer?.cancel();
    state.persist();
    unawaited(_saveBounds().whenComplete(wm.windowManager.destroy));
  }

  void minimize() => unawaited(wm.windowManager.minimize());

  /// Maximizes (zooms on macOS) or restores the window, going by what the window really is right now.
  Future<void> toggleMaximize() async {
    if (await wm.windowManager.isMaximized()) {
      await wm.windowManager.unmaximize();
    } else {
      await wm.windowManager.maximize();
    }
  }

  @override
  void onWindowClose() => quit();

  @override
  void onWindowMaximize() {
    setState(() => maximized = true);
    _saveBoundsSoon();
  }

  @override
  void onWindowUnmaximize() {
    setState(() => maximized = false);
    _saveBoundsSoon();
  }

  /// The title bar's window behaviour: drag to move, double click to maximize / zoom / restore, right click for the
  /// window menu (Windows and Linux). The same on every platform; only the window buttons and menus differ.
  WindowChrome get chrome => WindowChrome.desktop(
    isMac: isMac,
    maximized: maximized,
    onMinimize: minimize,
    onToggleMaximize: () => unawaited(toggleMaximize()),
    onClose: quit,
    onDragStart: () => unawaited(wm.windowManager.startDragging()),
    onContextMenu: () => unawaited(wm.windowManager.popUpWindowMenu()),
  );

  // macOS native menu bar

  List<PlatformMenuItem> _macMenus() {
    PlatformMenuItem item(MenuItemSpec e) => PlatformMenuItem(
      label: e.checked == true ? '✓ ${e.label}' : e.label,
      shortcut: e.shortcut?.toActivator(true),
      onSelected: e.enabled ? e.action : null,
    );

    List<PlatformMenuItem> groups(
      List<MenuEntry> items, {
      bool enabled = true,
    }) {
      final out = <PlatformMenuItem>[];
      var cur = <PlatformMenuItem>[];
      void flush() {
        if (cur.isNotEmpty) out.add(PlatformMenuItemGroup(members: cur));
        cur = <PlatformMenuItem>[];
      }

      for (final e in items) {
        switch (e) {
          case MenuSeparator():
            flush();
          case SubMenuSpec():
            cur.add(
              PlatformMenu(
                label: e.label,
                menus: groups(e.items, enabled: e.enabled && enabled),
              ),
            );
          case MenuItemSpec():
            cur.add(
              item(
                enabled
                    ? e
                    : MenuItemSpec(
                        e.label,
                        shortcut: e.shortcut,
                        enabled: false,
                        checked: e.checked,
                        action: e.action,
                      ),
              ),
            );
        }
      }
      flush();
      return out;
    }

    final app = PlatformMenu(
      label: AppConfig.NAME,
      menus: [
        PlatformMenuItemGroup(
          members: [
            PlatformMenuItem(
              label: 'About ${AppConfig.NAME}',
              onSelected: () => state.modal = const ModalAbout(),
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: [
            PlatformMenuItem(
              label: 'Preferences…',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.comma,
                meta: true,
              ),
              onSelected: () => state.modal = const ModalSettings(),
            ),
          ],
        ),
        const PlatformMenuItemGroup(
          members: [
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.servicesSubmenu,
            ),
          ],
        ),
        const PlatformMenuItemGroup(
          members: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.hideOtherApplications,
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.showAllApplications,
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: [
            PlatformMenuItem(
              label: 'Quit ${AppConfig.NAME}',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyQ,
                meta: true,
              ),
              onSelected: quit,
            ),
          ],
        ),
      ],
    );
    return [
      app,
      for (final m in AppMenus.build(
        state,
        isMac: true,
        quit: quit,
        minimize: minimize,
      ))
        PlatformMenu(label: m.label, menus: groups(m.items)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.NAME,
      theme: RocketTheme.data(dark),
      scrollBehavior: const _DesktopScrollBehavior(),
      builder: (context, child) => AppScope(
        state: state,
        child: ListenableBuilder(
          listenable: state,
          // Text scales with the interface-size setting, dp sizes do not.
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(state.settings.fontSize / 13),
            ),
            child: RocketTheme(dark: dark, child: child!),
          ),
        ),
      ),
      home: Material(
        type: MaterialType.transparency,
        child: Builder(
          builder: (context) {
            final Widget body = Stack(
              fit: StackFit.expand,
              children: [
                RocketApp(state: state, chrome: chrome),
                if (!isMac && !maximized) const ResizeEdges(),
              ],
            );
            if (!isMac) return body;
            return ListenableBuilder(
              listenable: state,
              builder: (context, _) =>
                  PlatformMenuBar(menus: _macMenus(), child: body),
            );
          },
        ),
      ),
    );
  }
}
