import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/layout.dart' show CONTROL_H;
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// A compact segmented selector that is as tall as a [Btn] (so it sits level with buttons): one option is filled
/// with the accent colour.
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.itemKey,
  });

  static const double _inset = 2;
  static const double _outerRadius = 6;

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  /// Key of the option's button, for tests.
  final Key? Function(String option)? itemKey;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const itemRadius = _outerRadius - _inset;
    return Container(
      height: CONTROL_H,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(_outerRadius),
      ),
      // The border is painted over the content so it takes no layout space.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_outerRadius),
        border: Border.all(color: p.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _inset,
        children: [
          for (final o in options)
            Clickable(
              key: itemKey?.call(o),
              onClick: () => onSelect(o),
              cursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(itemRadius),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: o == selected ? p.accent : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(itemRadius),
                ),
                child: T(
                  o,
                  color: o == selected ? const Color(0xFFFFFFFF) : p.text,
                  size: 12,
                  weight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
