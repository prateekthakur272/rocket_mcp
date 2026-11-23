import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/drag_devices.dart';
import 'package:rocket_mcp/components/overlay.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/features/shell/modals.dart';
import 'package:rocket_mcp/features/shell/status_bar.dart';
import 'package:rocket_mcp/features/shell/title_bar.dart';
import 'package:rocket_mcp/features/shell/window_chrome.dart';
import 'package:rocket_mcp/features/workspace/workspace_view.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// The window's content: title bar, sidebar and workspace, status bar, and the dialog and toast layers.
/// Place it below the theme and `AppScope` (see `main.dart`).
class RocketApp extends StatefulWidget {
  const RocketApp({
    super.key,
    required this.state,
    this.chrome = WindowChrome.none,
  });

  final AppState state;
  final WindowChrome chrome;

  @override
  State<RocketApp> createState() => _RocketAppState();
}

class _RocketAppState extends State<RocketApp> {
  static const Duration saveDelay = Duration(milliseconds: 500);

  final MenuOverlay menuOverlay = MenuOverlay();
  List<Object?> _layout = const [];
  Timer? _layoutTimer;

  @override
  void initState() {
    super.initState();
    _layout = widget.state.layoutSnapshot();
    widget.state.addListener(_saveLayoutSoon);
  }

  @override
  void dispose() {
    _layoutTimer?.cancel();
    widget.state.removeListener(_saveLayoutSoon);
    menuOverlay.dispose();
    super.dispose();
  }

  /// Layout changes are saved shortly after they happen, not only on quit.
  void _saveLayoutSoon() {
    final now = widget.state.layoutSnapshot();
    if (_sameValues(now, _layout)) return;
    _layout = now;
    _layoutTimer?.cancel();
    _layoutTimer = Timer(saveDelay, widget.state.persist);
  }

  static bool _sameValues(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// A press outside the open title-bar menu closes it without being consumed.
  void _pointerDown(PointerDownEvent event) {
    final menu = widget.state.titleMenu;
    if (menu.open == null) return;
    final inPanel = menu.panel?.contains(event.position) == true;
    final inTitle = menu.anchors.values.any((r) => r.contains(event.position));
    if (!inPanel && !inTitle) menu.close();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final p = context.pal;
        return LocalMenuOverlay(
          value: menuOverlay,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _pointerDown,
            child: Container(
              color: p.bg,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TitleBar(state: state, chrome: widget.chrome),
                      Expanded(child: _Body(state: state)),
                      StatusBar(state: state),
                    ],
                  ),
                  Modals(state: state),
                  MenuOverlayHost(overlay: menuOverlay),
                  if (state.toast != null) _Toast(message: state.toast!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Sidebar, its draggable divider and the workspace.
class _Body extends StatelessWidget {
  const _Body({required this.state});
  final AppState state;

  static const double minSidebarDp = 210;
  static const double maxSidebarDp = 480;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final sidebarDp = (totalWidth * state.sidebarWidth)
            .clamp(minSidebarDp, maxSidebarDp)
            .toDouble();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.sidebarVisible) ...[
              SizedBox(width: sidebarDp, child: const SidebarView()),
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  supportedDevices: kDragDevices,
                  onHorizontalDragUpdate: (d) =>
                      state.sidebarWidth += d.delta.dx / totalWidth,
                  child: Container(width: 5, color: p.border),
                ),
              ),
            ],
            Expanded(child: WorkspaceView(state: state)),
          ],
        );
      },
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: p.dark
                    ? const Color(0xFF3A3F47)
                    : const Color(0xFF1F2328),
                borderRadius: BorderRadius.circular(8),
              ),
              child: T(message, color: const Color(0xFFFFFFFF)),
            ),
          ),
        ),
      ),
    );
  }
}
