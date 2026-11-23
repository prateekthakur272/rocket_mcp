import 'package:flutter/widgets.dart';

/// A header bar with [leading] items at the start and [trailing] controls at the end.
///
/// The leading items give way when space runs short: each may shrink (text in them should use `maxLines: 1` and an
/// ellipsis), down to nothing. The trailing controls keep their size, and only scale down as a last resort when even
/// they do not fit the bar on their own.
class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.leading,
    required this.trailing,
    this.spacing = 8,
  });

  final List<Widget> leading;
  final List<Widget> trailing;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        Expanded(
          // The gap to the trailing controls lives inside the leading area, so it vanishes with it.
          child: Padding(
            padding: EdgeInsets.only(right: spacing),
            // The gaps are padding inside each item, not Row spacing, so they shrink away with the item instead of
            // forcing the row wider than the room it has.
            child: Row(
              children: [
                for (var i = 0; i < leading.length; i++)
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == leading.length - 1 ? 0 : spacing,
                      ),
                      child: leading[i],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Capped at the bar's own width: wider than that and the controls scale down instead of overflowing.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: spacing,
              children: trailing,
            ),
          ),
        ),
      ],
    ),
  );
}
