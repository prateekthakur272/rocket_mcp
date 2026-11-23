// ignore_for_file: constant_identifier_names, non_constant_identifier_names, deprecated_member_use
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:rocket_mcp/components/drag_devices.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:window_manager/legacy.dart' as wm;

/// What the app's own top bar has to do because the operating system's title bar is replaced by it.
///  - macOS keeps its native traffic-light buttons floating over the bar: [leftInset] leaves room for them.
///  - Windows / Linux draw nothing, so the app supplies its own [controls] (minimize / maximize / close).
///  - On every desktop platform the bar behaves like a native title bar: a [dragArea] moves the window, and
///    [onDoubleClick] maximizes / restores it (zoom on macOS). See [WindowChrome.desktop].
class WindowChrome {
  const WindowChrome({
    this.leftInset = 0,
    this.controls,
    this.dragArea = _identity,
    this.onDoubleClick,
    this.inlineMenus = false,
    this.onQuit = _noop,
    this.onMinimize = _noop,
  });

  final double leftInset;
  final Widget? controls;
  final Widget Function(Widget content) dragArea;
  final VoidCallback? onDoubleClick;

  /// Draw the menu bar inside the title bar (Windows / Linux), instead of the operating system's.
  final bool inlineMenus;
  final VoidCallback onQuit;
  final VoidCallback onMinimize;

  static const WindowChrome none = WindowChrome();

  /// The chrome of the real desktop window, with the same title-bar gestures on every platform:
  /// drag to move ([onDragStart]), double click to maximize / zoom / restore ([onToggleMaximize]) and right click
  /// for the window menu ([onContextMenu], where the platform has one). macOS also keeps room for its traffic lights;
  /// Windows and Linux get their own window buttons and the menus inside the bar.
  factory WindowChrome.desktop({
    required bool isMac,
    required bool maximized,
    required VoidCallback onMinimize,
    required VoidCallback onToggleMaximize,
    required VoidCallback onClose,
    required VoidCallback onDragStart,
    VoidCallback? onContextMenu,
  }) => WindowChrome(
    leftInset: isMac ? 72 : 0,
    controls: isMac
        ? null
        : WindowControls(
            maximized: maximized,
            onMinimize: onMinimize,
            onToggleMaximize: onToggleMaximize,
            onClose: onClose,
          ),
    dragArea: (content) => TitleBarDrag(
      onDragStart: onDragStart,
      onContextMenu: onContextMenu,
      child: content,
    ),
    onDoubleClick: onToggleMaximize,
    inlineMenus: !isMac,
    onQuit: isMac ? _noop : onClose,
    onMinimize: isMac ? _noop : onMinimize,
  );
}

Widget _identity(Widget w) => w;
void _noop() {}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.icon,
    required this.danger,
    required this.onClick,
  });
  final IconData icon;
  final bool danger;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return HoverBuilder(
      indicate: true,
      onTap: onClick,
      builder: (ctx, hov) => Container(
        width: 46,
        alignment: Alignment.center,
        color: hov
            ? (danger ? const Color(0xFFE81123) : p.hover)
            : const Color(0x00000000),
        child: Ico(
          icon,
          tint: hov && danger ? const Color(0xFFFFFFFF) : p.text,
          size: 15,
        ),
      ),
    );
  }
}

/// Minimize / maximize (or restore) / close, for platforms where the app draws its own title area.
class WindowControls extends StatelessWidget {
  const WindowControls({
    super.key,
    required this.maximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
  });

  final bool maximized;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _CaptionButton(
        icon: Icons.remove_rounded,
        danger: false,
        onClick: onMinimize,
      ),
      _CaptionButton(
        icon: maximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
        danger: false,
        onClick: onToggleMaximize,
      ),
      _CaptionButton(icon: Icons.close_rounded, danger: true, onClick: onClose),
    ],
  );
}

/// Dragging the bar moves the window and a right click opens the window menu, like a native title bar.
/// Buttons and other controls inside the bar still win their own clicks.
class TitleBarDrag extends StatelessWidget {
  const TitleBarDrag({
    super.key,
    required this.onDragStart,
    this.onContextMenu,
    required this.child,
  });

  final VoidCallback onDragStart;
  final VoidCallback? onContextMenu;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    supportedDevices: kDragDevices,
    onPanStart: (_) => onDragStart(),
    onSecondaryTap: onContextMenu,
    child: child,
  );
}

/// Double-clicking empty space in the bar maximizes / restores the window (zoom on macOS).
class TitleBarDoubleClick extends StatelessWidget {
  const TitleBarDoubleClick({
    super.key,
    required this.chrome,
    required this.child,
  });
  final WindowChrome chrome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final f = chrome.onDoubleClick;
    if (f == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: f,
      child: child,
    );
  }
}

/// Window position and size.
class Bounds {
  const Bounds(this.x, this.y, this.w, this.h);
  final int x;
  final int y;
  final int w;
  final int h;

  @override
  bool operator ==(Object other) =>
      other is Bounds &&
      other.x == x &&
      other.y == y &&
      other.w == w &&
      other.h == h;
  @override
  int get hashCode => Object.hash(x, y, w, h);
}

/// Window edge or corner used for resizing.
enum ResizeEdge { N, S, E, W, NE, NW, SE, SW }

/// New window bounds when an edge or corner is dragged by ([dx], [dy]) screen pixels; never smaller than the minimum, and the opposite edge stays put.
Bounds resizeBounds(
  ResizeEdge edge,
  Bounds start,
  int dx,
  int dy,
  int minW,
  int minH,
) {
  var x = start.x, y = start.y, w = start.w, h = start.h;
  final east =
      edge == ResizeEdge.E || edge == ResizeEdge.NE || edge == ResizeEdge.SE;
  final west =
      edge == ResizeEdge.W || edge == ResizeEdge.NW || edge == ResizeEdge.SW;
  final south =
      edge == ResizeEdge.S || edge == ResizeEdge.SE || edge == ResizeEdge.SW;
  final north =
      edge == ResizeEdge.N || edge == ResizeEdge.NE || edge == ResizeEdge.NW;
  if (east) w = start.w + dx > minW ? start.w + dx : minW;
  if (west) {
    w = start.w - dx > minW ? start.w - dx : minW;
    x = start.x + (start.w - w);
  }
  if (south) h = start.h + dy > minH ? start.h + dy : minH;
  if (north) {
    h = start.h - dy > minH ? start.h - dy : minH;
    y = start.y + (start.h - h);
  }
  return Bounds(x, y, w, h);
}

/// The window manager's native resize operation for each edge.
wm.ResizeEdge _native(ResizeEdge e) => switch (e) {
  ResizeEdge.N => wm.ResizeEdge.top,
  ResizeEdge.S => wm.ResizeEdge.bottom,
  ResizeEdge.E => wm.ResizeEdge.right,
  ResizeEdge.W => wm.ResizeEdge.left,
  ResizeEdge.NE => wm.ResizeEdge.topRight,
  ResizeEdge.NW => wm.ResizeEdge.topLeft,
  ResizeEdge.SE => wm.ResizeEdge.bottomRight,
  ResizeEdge.SW => wm.ResizeEdge.bottomLeft,
};

/// Invisible grab handles around an undecorated window so it can still be resized
/// (the window system performs the actual resize: `startResizing`). Place it in a window-filling `Stack`.
class ResizeEdges extends StatelessWidget {
  const ResizeEdges({super.key, this.thickness = 5});
  final double thickness;

  Widget _handle(ResizeEdge edge, MouseCursor cursor) => MouseRegion(
    cursor: cursor,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      supportedDevices: kDragDevices,
      onPanStart: (_) => wm.windowManager.startResizing(_native(edge)),
      child: const SizedBox.expand(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = thickness;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: t,
          child: _handle(ResizeEdge.N, SystemMouseCursors.resizeUp),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: t,
          child: _handle(ResizeEdge.S, SystemMouseCursors.resizeDown),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: t,
          child: _handle(ResizeEdge.W, SystemMouseCursors.resizeLeft),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: t,
          child: _handle(ResizeEdge.E, SystemMouseCursors.resizeRight),
        ),
        Positioned(
          left: 0,
          top: 0,
          width: t * 2,
          height: t * 2,
          child: _handle(ResizeEdge.NW, SystemMouseCursors.resizeUpLeft),
        ),
        Positioned(
          right: 0,
          top: 0,
          width: t * 2,
          height: t * 2,
          child: _handle(ResizeEdge.NE, SystemMouseCursors.resizeUpRight),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          width: t * 2,
          height: t * 2,
          child: _handle(ResizeEdge.SW, SystemMouseCursors.resizeDownLeft),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          width: t * 2,
          height: t * 2,
          child: _handle(ResizeEdge.SE, SystemMouseCursors.resizeDownRight),
        ),
      ],
    );
  }
}
