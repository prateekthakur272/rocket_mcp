// ignore_for_file: constant_identifier_names
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/drag_devices.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Height shared by buttons, dropdowns and single-line text fields.
const double CONTROL_H = 32;

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
            child: Container(
              width: width,
              height: height,
              constraints: height != null
                  ? null
                  : const BoxConstraints(maxHeight: 760),
              decoration: BoxDecoration(
                color: p.panel,
                borderRadius: BorderRadius.circular(10),
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
                            child: T(title, size: 15, weight: FontWeight.w600),
                          ),
                          IconBtn(icon: Ic.close, onClick: onClose),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    fit: height != null ? FlexFit.tight : FlexFit.loose,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: height != null
                            ? MainAxisSize.max
                            : MainAxisSize.min,
                        spacing: 10,
                        children: content,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 8,
                      children: actions,
                    ),
                  ),
                ],
              ),
            ),
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
    final p = context.pal;
    return LayoutBuilder(
      builder: (context, c) {
        final total = (vertical ? c.maxHeight : c.maxWidth).clamp(
          1.0,
          double.infinity,
        );
        final firstDp = total * fraction;
        const handle = 5.0;
        void drag(double d) =>
            onFraction(((fraction + d / total)).clamp(0.12, 0.88));
        if (vertical) {
          return Column(
            children: [
              SizedBox(height: firstDp, width: double.infinity, child: first),
              MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  supportedDevices: kDragDevices,
                  onVerticalDragUpdate: (d) => drag(d.delta.dy),
                  child: Container(
                    height: handle,
                    width: double.infinity,
                    color: p.border,
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(width: double.infinity, child: second),
              ),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: firstDp, height: double.infinity, child: first),
            MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                supportedDevices: kDragDevices,
                onHorizontalDragUpdate: (d) => drag(d.delta.dx),
                child: Container(
                  width: handle,
                  height: double.infinity,
                  color: p.border,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(height: double.infinity, child: second),
            ),
          ],
        );
      },
    );
  }
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
