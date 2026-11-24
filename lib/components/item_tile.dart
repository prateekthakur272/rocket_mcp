import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// A modern floating card-style list tile with an icon badge, title, optional
/// subtitle, and trailing widget. Selected tiles feature an elegant rounded
/// glow, border highlight, and chevron cue instead of a heavy edge bar.
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

  static const double _badgeSize = 24;

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: HoverBuilder(
        cursor: SystemMouseCursors.click,
        onTap: onClick,
        builder: (context, hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? p.accent.withValues(alpha: p.dark ? 0.16 : 0.08)
                : (hovered ? p.hover : const Color(0x00000000)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? p.accent.withValues(alpha: p.dark ? 0.38 : 0.25)
                  : (hovered
                        ? p.border.withValues(alpha: 0.5)
                        : const Color(0x00000000)),
              width: 1,
            ),
            boxShadow: selected && p.dark
                ? [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            spacing: 8,
            children: [
              Container(
                width: _badgeSize,
                height: _badgeSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Ico(icon, size: 13, tint: color),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1.5,
                  children: [
                    T(
                      title,
                      size: 12,
                      lineHeight: 1.25,
                      weight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? (p.dark ? const Color(0xFFFFFFFF) : p.text)
                          : p.text,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hint != null && hint.isNotEmpty)
                      T(
                        hint,
                        size: 9.5,
                        lineHeight: 1.25,
                        mono: monoSubtitle,
                        color: p.muted,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Ico(
                  Ic.chevronRight,
                  size: 11,
                  tint: selected
                      ? p.accent
                      : (hovered
                            ? p.muted.withValues(alpha: 0.8)
                            : const Color(0x00000000)),
                ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
