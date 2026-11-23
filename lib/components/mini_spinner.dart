import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// A small loading indicator for rows and buttons: three grey dots that swell and fade in turn, in the same quiet
/// grey as the neutral state graphics. It is as wide as it is
/// tall times about 2.2, so give it room for that.
class MiniSpinner extends StatefulWidget {
  const MiniSpinner({super.key, this.size = 11});

  /// The height of the largest dot; the whole indicator is wider.
  final double size;

  @override
  State<MiniSpinner> createState() => _MiniSpinnerState();
}

class _MiniSpinnerState extends State<MiniSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.pal.muted;
    final dot = widget.size * 0.42;
    return SizedBox(
      width: widget.size * 2.2,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 3; i++)
              _Dot(
                // Each dot peaks a third of a cycle after the one before it.
                level:
                    (math.sin((_controller.value - i / 3) * 2 * math.pi) + 1) /
                    2,
                size: dot,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.level, required this.size, required this.color});
  final double level;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.3 + level * 0.7,
    child: Container(
      width: size * (0.7 + level * 0.5),
      height: size * (0.7 + level * 0.5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
