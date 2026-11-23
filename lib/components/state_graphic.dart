import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// What an empty-state or status graphic is about.
enum StateGraphicType {
  disconnected,
  error,
  server,
  tools,
  prompts,
  resources,
  traffic,
  search,
  connecting,
  logs,
  empty,
  generic;

  /// The graphic that goes with an icon, so a screen can pass the icon it already uses.
  static StateGraphicType fromIcon(IconData? icon) {
    if (icon == null) return StateGraphicType.generic;
    if (icon == Ic.disconnect) return StateGraphicType.disconnected;
    if (icon == Ic.error || icon == Ic.warning) return StateGraphicType.error;
    if (icon == Ic.server) return StateGraphicType.server;
    if (icon == Ic.tool) return StateGraphicType.tools;
    if (icon == Ic.prompt) return StateGraphicType.prompts;
    if (icon == Ic.resource || icon == Ic.resourceTemplate) {
      return StateGraphicType.resources;
    }
    if (icon == Ic.traffic || icon == Ic.timer) return StateGraphicType.traffic;
    if (icon == Ic.search) return StateGraphicType.search;
    if (icon == Ic.connecting || icon == Ic.refresh) {
      return StateGraphicType.connecting;
    }
    if (icon == Ic.code || icon == Ic.fmtRaw) return StateGraphicType.logs;
    if (icon == Ic.checkCircle) return StateGraphicType.empty;
    return StateGraphicType.generic;
  }
}

/// The illustration above an empty-state message: flat, abstract 2D art built from simple shapes (rounded blocks, rings,
/// arcs, lines and dots) over a soft blob. Each kind of screen has its own composition, but they share one palette and
/// one drawing style, so they read as a set. The "connecting" art is the only one that moves: ripples spreading from a dot.
class StateGraphic extends StatefulWidget {
  const StateGraphic({
    super.key,
    this.type,
    this.icon,
    this.compact = false,
    this.size,
    this.color,
  });

  const StateGraphic.disconnected({
    super.key,
    this.compact = false,
    this.size,
    this.color,
  }) : type = StateGraphicType.disconnected,
       icon = null;

  const StateGraphic.error({
    super.key,
    this.compact = false,
    this.size,
    this.color,
  }) : type = StateGraphicType.error,
       icon = null;

  const StateGraphic.server({
    super.key,
    this.compact = false,
    this.size,
    this.color,
  }) : type = StateGraphicType.server,
       icon = null;

  const StateGraphic.tools({
    super.key,
    this.compact = false,
    this.size,
    this.color,
  }) : type = StateGraphicType.tools,
       icon = null;

  const StateGraphic.prompts({
    super.key,
    this.compact = false,
    this.size,
    this.color,
  }) : type = StateGraphicType.prompts,
       icon = null;

  const StateGraphic.resources({
    super.key,
    this.compact = false,
    this.size,
    this.color,
  }) : type = StateGraphicType.resources,
       icon = null;

  const StateGraphic.traffic({
    super.key,
    this.compact = false,
    this.size,
    this.color,
  }) : type = StateGraphicType.traffic,
       icon = null;

  static const double _regularSize = 104;
  static const double _compactSize = 64;

  final StateGraphicType? type;

  /// The icon to illustrate when no [type] is given; a known icon picks its type.
  final IconData? icon;
  final bool compact;
  final double? size;

  /// Overrides the main colour the type would pick.
  final Color? color;

  @override
  State<StateGraphic> createState() => _StateGraphicState();
}

class _StateGraphicState extends State<StateGraphic>
    with SingleTickerProviderStateMixin {
  AnimationController? _spin;

  StateGraphicType get _kind =>
      widget.type ?? StateGraphicType.fromIcon(widget.icon);

  @override
  void initState() {
    super.initState();
    _syncSpin();
  }

  @override
  void didUpdateWidget(StateGraphic old) {
    super.didUpdateWidget(old);
    _syncSpin();
  }

  /// Only the connecting art moves; the controller exists only while it is shown.
  void _syncSpin() {
    if (_kind == StateGraphicType.connecting) {
      _spin ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..repeat();
    } else {
      _spin?.dispose();
      _spin = null;
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  /// The one coloured element of each graphic, always a touch of red; everything else is grey.
  Color _accent(Pal p) =>
      _kind == StateGraphicType.error || _kind == StateGraphicType.disconnected
      ? p.err
      : p.accent;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s =
        widget.size ??
        (widget.compact
            ? StateGraphic._compactSize
            : StateGraphic._regularSize);
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(
        size: Size.square(s),
        painter: _ArtPainter(
          progress: _spin,
          kind: _kind,
          tint: p.muted,
          accent: widget.color ?? _accent(p),
          panel: p.panel,
        ),
      ),
    );
  }
}

/// Draws one composition on a square canvas, in coordinates from 0 to 1. Every shape is [tint] (a grey); the one
/// element that matters is drawn in [accent].
class _ArtPainter extends CustomPainter {
  _ArtPainter({
    this.progress,
    required this.kind,
    required this.tint,
    required this.accent,
    required this.panel,
  }) : super(repaint: progress);

  /// 0 to 1, repeating, for the animated art; null for the still ones.
  final Animation<double>? progress;

  final StateGraphicType kind;
  final Color tint;
  final Color accent;
  final Color panel;

  late double _s;
  late Canvas _c;

  static const Color _white = Color(0xFFFFFFFF);

  Paint _fill(Color color) => Paint()
    ..color = color
    ..isAntiAlias = true;

  Paint _line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width * _s
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  Color _grey(double alpha) => tint.withValues(alpha: alpha);

  Offset _o(double x, double y) => Offset(x * _s, y * _s);

  void _circle(double x, double y, double r, Paint paint) =>
      _c.drawCircle(_o(x, y), r * _s, paint);

  void _block(double x, double y, double w, double h, double r, Paint paint) =>
      _c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * _s, y * _s, w * _s, h * _s),
          Radius.circular(r * _s),
        ),
        paint,
      );

  void _segment(double x1, double y1, double x2, double y2, Paint paint) =>
      _c.drawLine(_o(x1, y1), _o(x2, y2), paint);

  void _triangle(List<Offset> points, Paint paint) {
    final path = Path()..moveTo(points[0].dx * _s, points[0].dy * _s);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx * _s, point.dy * _s);
    }
    _c.drawPath(path..close(), paint);
  }

  /// A rounded square of side [side] centred on (x, y), turned by [angle].
  void _turnedSquare(
    double x,
    double y,
    double side,
    double radius,
    double angle,
    Paint paint,
  ) {
    _c.save();
    _c.translate(x * _s, y * _s);
    _c.rotate(angle);
    _c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: side * _s,
          height: side * _s,
        ),
        Radius.circular(radius * _s),
      ),
      paint,
    );
    _c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    _s = size.width;
    _backdrop();
    switch (kind) {
      case StateGraphicType.server:
        _server();
      case StateGraphicType.disconnected:
        _disconnected();
      case StateGraphicType.error:
        _error();
      case StateGraphicType.tools:
        _tools();
      case StateGraphicType.prompts:
        _prompts();
      case StateGraphicType.resources:
        _resources();
      case StateGraphicType.traffic:
        _traffic();
      case StateGraphicType.search:
        _search();
      case StateGraphicType.connecting:
        _connecting();
      case StateGraphicType.logs:
        _logs();
      case StateGraphicType.empty:
        _empty();
      case StateGraphicType.generic:
        _generic();
    }
  }

  /// A grey blob, a few scattered dots and a plus, shared by every composition; one dot takes the accent colour.
  void _backdrop() {
    _circle(0.5, 0.5, 0.46, _fill(_grey(0.1)));
    _circle(0.14, 0.32, 0.018, _fill(_grey(0.4)));
    _circle(0.88, 0.22, 0.024, _fill(accent.withValues(alpha: 0.7)));
    _circle(0.82, 0.84, 0.014, _fill(_grey(0.4)));
    final plus = _line(_grey(0.45), 0.014);
    _segment(0.12, 0.78, 0.12, 0.86, plus);
    _segment(0.08, 0.82, 0.16, 0.82, plus);
  }

  /// Three stacked server blades; the top one is the accent.
  void _server() {
    for (var i = 0; i < 3; i++) {
      final top = i == 2;
      final y = 0.2 + i * 0.205;
      _block(
        0.2,
        y,
        0.6,
        0.17,
        0.05,
        _fill(top ? accent : _grey(0.18 + i * 0.1)),
      );
      final ink = top ? _white : _grey(0.7);
      _circle(0.29, y + 0.085, 0.022, _fill(ink));
      _segment(
        0.38,
        y + 0.085,
        0.38 + 0.2 - i * 0.03,
        y + 0.085,
        _line(ink, 0.02),
      );
      _circle(0.72, y + 0.085, 0.015, _fill(ink.withValues(alpha: 0.7)));
    }
  }

  /// Two blocks that no longer touch, a broken line and a slash in the accent.
  void _disconnected() {
    _block(0.1, 0.4, 0.27, 0.2, 0.06, _fill(_grey(0.4)));
    _block(0.63, 0.4, 0.27, 0.2, 0.06, _fill(_grey(0.4)));
    _circle(0.1, 0.5, 0.045, _fill(panel));
    _circle(0.9, 0.5, 0.045, _fill(panel));
    final dash = _line(_grey(0.8), 0.02);
    _segment(0.4, 0.5, 0.44, 0.5, dash);
    _segment(0.56, 0.5, 0.6, 0.5, dash);
    _segment(0.38, 0.72, 0.62, 0.28, _line(accent, 0.045));
  }

  /// A grey diamond with a red exclamation mark.
  void _error() {
    _circle(0.5, 0.5, 0.34, _fill(_grey(0.14)));
    _turnedSquare(0.5, 0.5, 0.42, 0.08, math.pi / 4, _fill(_grey(0.75)));
    final mark = _fill(accent);
    _block(0.475, 0.36, 0.05, 0.17, 0.025, mark);
    _circle(0.5, 0.61, 0.03, mark);
  }

  /// A grey gear and a small accent ring.
  void _tools() {
    const teeth = 8;
    final tooth = _line(_grey(0.75), 0.085);
    for (var i = 0; i < teeth; i++) {
      final a = i * 2 * math.pi / teeth;
      _segment(
        0.46 + math.cos(a) * 0.255,
        0.46 + math.sin(a) * 0.255,
        0.46 + math.cos(a) * 0.3,
        0.46 + math.sin(a) * 0.3,
        tooth,
      );
    }
    _circle(0.46, 0.46, 0.255, _fill(_grey(0.75)));
    _circle(0.46, 0.46, 0.105, _fill(panel));
    _circle(0.46, 0.46, 0.04, _fill(_grey(0.4)));
    _circle(0.76, 0.76, 0.1, _line(accent, 0.04));
    _circle(0.76, 0.76, 0.03, _fill(accent));
  }

  /// Two overlapping speech bubbles; the front one is the accent.
  void _prompts() {
    _block(0.14, 0.2, 0.56, 0.38, 0.1, _fill(_grey(0.22)));
    _triangle(const [
      Offset(0.24, 0.55),
      Offset(0.24, 0.7),
      Offset(0.38, 0.55),
    ], _fill(_grey(0.22)));
    final text = _line(_grey(0.7), 0.025);
    _segment(0.24, 0.32, 0.56, 0.32, text);
    _segment(0.24, 0.42, 0.46, 0.42, text);
    _block(0.46, 0.46, 0.4, 0.28, 0.09, _fill(accent));
    _triangle(const [
      Offset(0.76, 0.72),
      Offset(0.76, 0.84),
      Offset(0.66, 0.72),
    ], _fill(accent));
    final dot = _fill(_white);
    for (var i = 0; i < 3; i++) {
      _circle(0.56 + i * 0.1, 0.6, 0.025, dot);
    }
  }

  /// Three fanned sheets; the front one carries an accent dot.
  void _resources() {
    for (var i = 0; i < 3; i++) {
      final front = i == 2;
      final x = 0.16 + i * 0.1;
      final y = 0.14 + i * 0.07;
      _block(
        x,
        y,
        0.46,
        0.58,
        0.07,
        _fill(front ? panel : _grey(0.12 + i * 0.1)),
      );
      if (front) {
        _block(x, y, 0.46, 0.58, 0.07, _line(_grey(0.7), 0.022));
        _segment(
          x + 0.09,
          y + 0.15,
          x + 0.37,
          y + 0.15,
          _line(_grey(0.8), 0.025),
        );
        final soft = _line(_grey(0.5), 0.025);
        _segment(x + 0.09, y + 0.26, x + 0.31, y + 0.26, soft);
        _segment(x + 0.09, y + 0.37, x + 0.34, y + 0.37, soft);
        _circle(x + 0.37, y + 0.48, 0.045, _fill(accent));
      }
    }
  }

  /// Two arrows travelling in opposite directions; the outgoing one is the accent.
  void _traffic() {
    _segment(0.16, 0.36, 0.7, 0.36, _line(accent, 0.04));
    _triangle(const [
      Offset(0.68, 0.24),
      Offset(0.68, 0.48),
      Offset(0.84, 0.36),
    ], _fill(accent));
    final back = _grey(0.7);
    _segment(0.84, 0.64, 0.3, 0.64, _line(back, 0.04));
    _triangle(const [
      Offset(0.32, 0.52),
      Offset(0.32, 0.76),
      Offset(0.16, 0.64),
    ], _fill(back));
    _circle(0.34, 0.36, 0.03, _fill(panel));
    _circle(0.54, 0.64, 0.03, _fill(panel));
  }

  /// A grey magnifier lens with an accent handle.
  void _search() {
    _circle(0.44, 0.44, 0.24, _fill(_grey(0.16)));
    _circle(0.44, 0.44, 0.24, _line(_grey(0.75), 0.06));
    _c.drawArc(
      Rect.fromCircle(center: _o(0.44, 0.44), radius: 0.15 * _s),
      math.pi * 1.1,
      math.pi * 0.5,
      false,
      _line(_grey(0.5), 0.03),
    );
    _segment(0.62, 0.62, 0.8, 0.8, _line(accent, 0.09));
  }

  /// Grey ripples spreading from an accent dot and fading out, half a cycle apart.
  void _connecting() {
    final t = progress?.value ?? 0.3;
    for (final phase in const [0.0, 0.5]) {
      final k = (t + phase) % 1;
      _circle(0.5, 0.5, 0.1 + k * 0.34, _line(_grey((1 - k) * 0.7), 0.035));
    }
    _circle(0.5, 0.5, 0.075 + math.sin(t * math.pi * 2) * 0.01, _fill(accent));
  }

  /// Lines of text, the first one the accent.
  void _logs() {
    const lengths = [0.5, 0.36, 0.44, 0.28, 0.4];
    for (var i = 0; i < lengths.length; i++) {
      final y = 0.22 + i * 0.14;
      final color = i == 0 ? accent : _grey(0.5);
      _circle(0.22, y, 0.025, _fill(color));
      _segment(0.32, y, 0.32 + lengths[i], y, _line(color, 0.04));
    }
  }

  /// A grey circle with a red check mark.
  void _empty() {
    _circle(0.5, 0.5, 0.3, _fill(_grey(0.14)));
    _circle(0.5, 0.5, 0.3, _line(_grey(0.45), 0.02));
    final check = Path()
      ..moveTo(0.37 * _s, 0.5 * _s)
      ..lineTo(0.46 * _s, 0.59 * _s)
      ..lineTo(0.64 * _s, 0.4 * _s);
    _c.drawPath(check, _line(accent, 0.07));
  }

  /// A circle, a rotated square and a triangle overlapping; the square is the accent.
  void _generic() {
    _circle(0.4, 0.44, 0.22, _fill(_grey(0.35)));
    _turnedSquare(0.6, 0.56, 0.34, 0.06, math.pi / 8, _fill(accent));
    _triangle(const [
      Offset(0.2, 0.78),
      Offset(0.34, 0.56),
      Offset(0.48, 0.78),
    ], _fill(_grey(0.55)));
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.kind != kind ||
      old.tint != tint ||
      old.accent != accent ||
      old.panel != panel;
}
