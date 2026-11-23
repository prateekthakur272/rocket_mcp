import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show
        ScrollbarTheme,
        ScrollbarThemeData,
        WidgetState,
        WidgetStateProperty,
        WidgetStatePropertyAll;
import 'package:rocket_mcp/theme/theme.dart';

/// Clickable with no ripple or hover indication: for backdrops and panels that only swallow or dismiss clicks.
class ClickableNoRipple extends StatelessWidget {
  const ClickableNoRipple({super.key, this.onClick, required this.child});

  final VoidCallback? onClick;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onClick ?? () {},
    child: child,
  );
}

/// Tracks hover state and shows the pointer cursor.
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({
    super.key,
    required this.builder,
    this.cursor = MouseCursor.defer,
    this.onTap,
    this.opaque = true,
    this.indicate = false,
    this.borderRadius,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final MouseCursor cursor;
  final VoidCallback? onTap;
  final bool opaque;

  /// When true (and [onTap] is set) a hover overlay (8%) and press ripple are drawn above the
  /// content, clipped to [borderRadius].
  final bool indicate;
  final BorderRadius? borderRadius;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    Widget w = MouseRegion(
      cursor: widget.cursor,
      opaque: widget.opaque,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: widget.builder(context, _hov),
    );
    if (widget.onTap != null && widget.indicate) {
      w = Clickable(
        onClick: widget.onTap,
        cursor: widget.cursor,
        borderRadius: widget.borderRadius,
        child: w,
      );
    } else if (widget.onTap != null) {
      w = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: w,
      );
    }
    return w;
  }
}

/// A 1px line along the bottom edge, drawn behind the child.
class DrawBottomBorder extends StatelessWidget {
  const DrawBottomBorder({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BottomBorderPainter(color), child: child);
}

class _BottomBorderPainter extends CustomPainter {
  _BottomBorderPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = color
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BottomBorderPainter old) => old.color != color;
}

/// Clickable with a Material-style indication: on hover a translucent overlay of the
/// content colour (alpha 0.08), on press a ripple (alpha 0.10) clipped to [borderRadius] (rectangular when null).
/// Drawn in the foreground (above the child's own backgrounds) and independent of any Material ancestor.
/// [overlayColor] defaults to the palette `text` colour.
class Clickable extends StatefulWidget {
  const Clickable({
    super.key,
    required this.onClick,
    this.enabled = true,
    this.borderRadius,
    this.cursor = SystemMouseCursors.basic,
    this.overlayColor,
    this.behavior = HitTestBehavior.opaque,
    required this.child,
  });

  final VoidCallback? onClick;
  final bool enabled;
  final BorderRadius? borderRadius;
  final MouseCursor cursor;
  final Color? overlayColor;
  final HitTestBehavior behavior;
  final Widget child;

  @override
  State<Clickable> createState() => _ClickableState();
}

class _ClickableState extends State<Clickable> with TickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    value: 1,
  );
  bool _hov = false;
  bool _down = false;
  Offset _origin = Offset.zero;

  bool get _on => widget.enabled && widget.onClick != null;

  @override
  void dispose() {
    _ctl.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _press(TapDownDetails d) {
    _origin = d.localPosition;
    _down = true;
    _ctl.forward(from: 0);
    _fade.value = 0;
    setState(() {});
  }

  void _release() {
    if (!_down) return;
    setState(() => _down = false);
    _fade.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_on) return MouseRegion(opaque: false, child: widget.child);
    final color = widget.overlayColor ?? Pal.of(context).text;
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _press,
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        onTap: widget.onClick,
        child: CustomPaint(
          foregroundPainter: _IndicationPainter(
            color: color,
            hovered: _hov,
            pressed: _down,
            origin: _origin,
            radius: widget.borderRadius,
            progress: _ctl,
            fade: _fade,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _IndicationPainter extends CustomPainter {
  _IndicationPainter({
    required this.color,
    required this.hovered,
    required this.pressed,
    required this.origin,
    required this.radius,
    required this.progress,
    required this.fade,
  }) : super(repaint: Listenable.merge([progress, fade]));

  final Color color;
  final bool hovered;
  final bool pressed;
  final Offset origin;
  final BorderRadius? radius;
  final Animation<double> progress;
  final Animation<double> fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.save();
    if (radius != null) {
      canvas.clipRRect(radius!.toRRect(rect));
    } else {
      canvas.clipRect(rect);
    }
    if (hovered) {
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.08));
    }
    final t = progress.value;
    // Ripple: expands from the press point while pressed; once released it finishes expanding then fades out.
    if (pressed || fade.value < 1) {
      final far = [
        origin.distance,
        (origin - Offset(size.width, 0)).distance,
        (origin - Offset(0, size.height)).distance,
        (origin - Offset(size.width, size.height)).distance,
      ].reduce((a, b) => a > b ? a : b);
      final r = far * Curves.easeOut.transform(t);
      final alpha = pressed ? 0.10 : 0.10 * (1 - fade.value);
      canvas.drawCircle(
        origin,
        r,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IndicationPainter o) =>
      o.color != color ||
      o.hovered != hovered ||
      o.pressed != pressed ||
      o.origin != origin ||
      o.radius != radius;
}

/// Styles a descendant `Scrollbar`: 8dp thumb, always visible,
/// black at 12% (50% when hovered or dragged).
Widget overlayScrollbarTheme(Widget child) => ScrollbarTheme(
  data: ScrollbarThemeData(
    thumbVisibility: const WidgetStatePropertyAll(true),
    thickness: const WidgetStatePropertyAll(8),
    radius: const Radius.circular(4),
    minThumbLength: 16,
    crossAxisMargin: 0,
    mainAxisMargin: 0,
    thumbColor: WidgetStateProperty.resolveWith(
      (s) => const Color(0xFF000000).withValues(
        alpha:
            s.contains(WidgetState.hovered) || s.contains(WidgetState.dragged)
            ? 0.5
            : 0.12,
      ),
    ),
  ),
  child: child,
);
