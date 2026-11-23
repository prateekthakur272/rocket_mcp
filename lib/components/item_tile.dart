import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// A list tile with a tinted icon badge, a title, an optional one-line subtitle and an optional trailing widget.
/// The selected tile has a tinted background and an accent bar on its left edge, like the sidebar's server rows.
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onClick,
    this.subtitle,
    this.monoSubtitle = false,
    this.tint,
    this.trailing,
  });

  static const double _badgeSize = 26;
  static const double _selectionBarWidth = 2.5;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Draws the subtitle in the monospace font (for URIs and templates).
  final bool monoSubtitle;
  final bool selected;
  final VoidCallback onClick;

  /// The badge colour; defaults to the accent colour.
  final Color? tint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = tint ?? p.accent;
    final hint = subtitle;
    return HoverBuilder(
      cursor: SystemMouseCursors.click,
      onTap: onClick,
      builder: (context, hovered) => Container(
        color: selected
            ? p.selected
            : (hovered ? p.hover : const Color(0x00000000)),
        child: Stack(
          children: [
            if (selected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _selectionBarWidth,
                child: ColoredBox(color: p.accent),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                spacing: 8,
                children: [
                  Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: selected ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Ico(icon, size: 14, tint: color),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 1,
                      children: [
                        T(
                          title,
                          size: 12.5,
                          lineHeight: 1.3,
                          weight: selected ? FontWeight.w600 : FontWeight.w500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hint != null && hint.isNotEmpty)
                          T(
                            hint,
                            size: 10,
                            lineHeight: 1.3,
                            mono: monoSubtitle,
                            color: p.muted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small muted label such as a MIME type, shown at the end of a tile.
class TileBadge extends StatelessWidget {
  const TileBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: p.muted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: T(
        label,
        size: 9,
        lineHeight: 1.1,
        mono: true,
        weight: FontWeight.w600,
        color: p.muted,
      ),
    );
  }
}
