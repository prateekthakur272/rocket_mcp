import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Related icon buttons in one bordered, rounded group with a hairline between them. Children are [IconBtn]s; use
/// [IconBtnGroup.boxSize] and [IconBtnGroup.iconSize] for them so the group is the same height as other controls.
class IconBtnGroup extends StatelessWidget {
  const IconBtnGroup({super.key, required this.children});

  /// Box and icon size of the buttons inside a group.
  static const double boxSize = 26;
  static const double iconSize = 15;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(6),
      ),
      // The border is painted over the content so it takes no layout space.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(width: 1, height: 16, color: p.border),
            children[i],
          ],
        ],
      ),
    );
  }
}
