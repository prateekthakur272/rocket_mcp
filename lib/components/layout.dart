// ignore_for_file: constant_identifier_names
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/drag_devices.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Height shared by buttons, dropdowns and single-line text fields.
const double CONTROL_H = 28;

/// Horizontal tab strip.
class Tabs extends StatelessWidget {
  const Tabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    this.badge,
  });

  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;
  final String? Function(String)? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return DrawBottomBorder(
      color: p.border,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 2,
          children: [
            for (final t in items)
              Builder(
                builder: (context) {
                  final sel = t == selected;
                  final b = badge?.call(t);
                  return Clickable(
                    onClick: () => onSelect(t),
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 8,
                      ),
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 4,
                              children: [
                                T(
                                  t,
                                  color: sel ? p.text : p.muted,
                                  weight: sel ? FontWeight.w600 : null,
                                ),
                                if (b != null)
                                  T(
                                    b,
                                    color: p.accent,
                                    size: 11,
                                    weight: FontWeight.w600,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 2,
                              color: sel ? p.accent : const Color(0x00000000),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Centered dialog panel.
class ModalBox extends StatelessWidget {
  /// Space kept between a dialog and the window edges, and the tallest a dialog may be.
  static const double _windowMargin = 48;
  static const double _maxDialogHeight = 760;

  const ModalBox({
    super.key,
    required this.title,
    required this.onClose,
    this.width = 560,
    this.height,
    this.actions = const [],
    this.content = const [],
  });

  final String title;
  final VoidCallback onClose;
  final double width;
  final double? height;
  final List<Widget> actions;
  final List<Widget> content;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ClickableNoRipple(
        onClick: onClose,
        child: Container(
          color: const Color(0xFF000000).withValues(alpha: 0.5),
          alignment: Alignment.center,
          child: ClickableNoRipple(
            // The dialog never grows taller than the window (less a margin); a tall form scrolls inside it.
            child: LayoutBuilder(
              builder: (context, outer) => Container(
                width: width,
                height: height,
                constraints: height != null
                    ? null
                    : BoxConstraints(
                        maxHeight: (outer.maxHeight - _windowMargin).clamp(
                          200.0,
                          _maxDialogHeight,
                        ),
                      ),
                decoration: BoxDecoration(
                  color: p.panel,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                // Border is painted over the content so it keeps the full outer width.
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.border, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: height != null
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DrawBottomBorder(
                      color: p.border,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: T(
                                title,
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                            IconBtn(icon: Ic.close, onClick: onClose),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      fit: height != null ? FlexFit.tight : FlexFit.loose,
                      child: height != null
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                spacing: 10,
                                children: content,
                              ),
                            )
                          : SingleChildScrollView(
                              primary: false,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                spacing: 10,
                                children: content,
                              ),
                            ),
                    ),
                    if (actions.isNotEmpty)
                      DrawTopBorder(
                        color: p.border,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            spacing: 8,
                            children: actions,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal dialog scaffold matching modern DevSpace dialog style with customizable width, maxHeight, and actions.
class ModalScaffold extends StatelessWidget {
  const ModalScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.actions = const [],
    this.width = 540,
    this.maxHeight,
    this.bodyPadding = const EdgeInsets.all(16),
  });

  final String title;
  final Widget child;

  /// Space around [child]; zero lets the body run edge to edge (for a side pane).
  final EdgeInsets bodyPadding;
  final VoidCallback onClose;
  final List<Widget> actions;
  final double width;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ClickableNoRipple(
        onClick: onClose,
        child: Container(
          color: const Color(0xFF000000).withValues(alpha: 0.5),
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxScreenHeight = constraints.maxHeight;
              final chromeHeight =
                  48 + 48 + 32 + (actions.isNotEmpty ? 56 : 0) + 2;
              final maxBodyHeight = (maxScreenHeight - chromeHeight).clamp(
                80.0,
                maxHeight != null
                    ? (maxHeight! - chromeHeight + 48)
                    : double.infinity,
              );

              return ClickableNoRipple(
                onClick: () {},
                child: Container(
                  width: width,
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: p.panel,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DrawBottomBorder(
                          color: p.border,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: T(
                                    title,
                                    size: 14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                IconBtn(
                                  icon: Ic.close,
                                  onClick: onClose,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxBodyHeight),
                          child: Padding(padding: bodyPadding, child: child),
                        ),
                        if (actions.isNotEmpty)
                          DrawTopBorder(
                            color: p.border,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                spacing: 8,
                                children: actions,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Two panes separated by a draggable divider.
class SplitPane extends StatelessWidget {
  const SplitPane({
    super.key,
    required this.vertical,
    required this.fraction,
    required this.onFraction,
    required this.first,
    required this.second,
  });

  final bool vertical;
  final double fraction;
  final ValueChanged<double> onFraction;
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final total = (vertical ? c.maxHeight : c.maxWidth).clamp(
          1.0,
          double.infinity,
        );
        final firstDp = total * fraction;
        void drag(double d) =>
            onFraction(((fraction + d / total)).clamp(0.12, 0.88));
        if (vertical) {
          return Column(
            children: [
              SizedBox(height: firstDp, width: double.infinity, child: first),
              PanelDivider(vertical: true, onDrag: drag),
              Expanded(
                child: SizedBox(width: double.infinity, child: second),
              ),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: firstDp, height: double.infinity, child: first),
            PanelDivider(vertical: false, onDrag: drag),
            Expanded(
              child: SizedBox(height: double.infinity, child: second),
            ),
          ],
        );
      },
    );
  }
}

/// A sleek, narrow panel divider with hover highlight and a 3-dot indicator at the center.
class PanelDivider extends StatefulWidget {
  const PanelDivider({
    super.key,
    this.vertical = false,
    required this.onDrag,
    this.thickness = 3.0,
  });

  /// When true, divides top and bottom panes (dragged vertically).
  /// When false, divides left and right panes (dragged horizontally).
  final bool vertical;
  final ValueChanged<double> onDrag;
  final double thickness;

  @override
  State<PanelDivider> createState() => _PanelDividerState();
}

class _PanelDividerState extends State<PanelDivider> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final active = _hovered || _dragging;
    final isVert = widget.vertical;

    return MouseRegion(
      cursor: isVert
          ? SystemMouseCursors.resizeUpDown
          : SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        supportedDevices: kDragDevices,
        onHorizontalDragStart: isVert
            ? null
            : (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: isVert
            ? null
            : (d) => widget.onDrag(d.delta.dx),
        onHorizontalDragEnd: isVert
            ? null
            : (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: isVert
            ? null
            : () => setState(() => _dragging = false),
        onVerticalDragStart: isVert
            ? (_) => setState(() => _dragging = true)
            : null,
        onVerticalDragUpdate: isVert ? (d) => widget.onDrag(d.delta.dy) : null,
        onVerticalDragEnd: isVert
            ? (_) => setState(() => _dragging = false)
            : null,
        onVerticalDragCancel: isVert
            ? () => setState(() => _dragging = false)
            : null,
        child: Container(
          width: isVert ? double.infinity : widget.thickness,
          height: isVert ? widget.thickness : double.infinity,
          color: active ? p.accent.withValues(alpha: 0.6) : p.border,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedOpacity(
                opacity: active ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  width: isVert ? 26 : 7,
                  height: isVert ? 7 : 26,
                  decoration: BoxDecoration(
                    color: p.panel,
                    borderRadius: BorderRadius.circular(3.5),
                    border: Border.all(
                      color: p.accent.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: isVert
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _dot(p.accent),
                            const SizedBox(width: 2.5),
                            _dot(p.accent),
                            const SizedBox(width: 2.5),
                            _dot(p.accent),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _dot(p.accent),
                            const SizedBox(height: 2.5),
                            _dot(p.accent),
                            const SizedBox(height: 2.5),
                            _dot(p.accent),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 2,
    height: 2,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Scrollable area with a visible scrollbar.
class ScrollBox extends StatelessWidget {
  const ScrollBox({super.key, this.content = const [], this.controller});

  final List<Widget> content;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: SingleChildScrollView(
      controller: controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
    ),
  );
}

/// Animated disclosure chevron: points right when collapsed, rotates to point down when open.
class Chevron extends StatelessWidget {
  const Chevron({super.key, required this.open, this.color});

  final bool open;
  final Color? color;

  @override
  Widget build(BuildContext context) => AnimatedRotation(
    turns: open ? 0.25 : 0,
    duration: const Duration(milliseconds: 140),
    curve: Curves.fastOutSlowIn,
    child: SizedBox(
      width: 14,
      height: 14,
      child: CustomPaint(painter: _ChevronPainter(color ?? context.pal.muted)),
    ),
  );
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.36, h * 0.22)
      ..lineTo(w * 0.66, h * 0.5)
      ..lineTo(w * 0.36, h * 0.78);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

class FolderIcon extends StatelessWidget {
  const FolderIcon({super.key, required this.open, this.color});

  final bool open;
  final Color? color;

  @override
  Widget build(BuildContext context) => Ico(
    open ? Ic.folderOpen : Ic.folder,
    tint: color ?? context.pal.accent,
    size: 18,
  );
}
