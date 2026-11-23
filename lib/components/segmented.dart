import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// A bordered segmented selector: one option is filled with the accent colour.
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.itemKey,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  /// Key of the option's button, for tests.
  final Key? Function(String option)? itemKey;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      // Borders are painted over the content so they take no layout space.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final o in options)
            Clickable(
              key: itemKey?.call(o),
              onClick: () => onSelect(o),
              cursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: o == selected ? p.accent : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: T(
                  o,
                  color: o == selected ? const Color(0xFF000000) : p.text,
                  size: 12,
                  weight: o == selected ? FontWeight.w600 : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
