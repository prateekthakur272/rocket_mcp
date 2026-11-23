import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// An [IconBtn] with a small count badge on its top-right corner, tinted [color].
class BadgeIconBtn extends StatelessWidget {
  const BadgeIconBtn({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
    required this.onClick,
    this.tooltip,
  });

  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback onClick;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconBtn(
          icon: icon,
          color: color,
          tooltip: tooltip,
          boxSize: 32,
          size: 17,
          onClick: onClick,
        ),
        Positioned(
          top: -3,
          right: -3,
          child: IgnorePointer(
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.field, width: 1.5),
              ),
              child: T(
                '$count',
                size: 9.5,
                lineHeight: 1.2,
                mono: true,
                weight: FontWeight.w700,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
