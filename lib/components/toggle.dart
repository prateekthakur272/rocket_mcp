import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// An on / off switch.
class Toggle extends StatelessWidget {
  const Toggle({super.key, required this.on, required this.onChange});
  final bool on;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Clickable(
      onClick: () => onChange(!on),
      cursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? p.accent : p.border,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
