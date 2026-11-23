import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/state_graphic.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// A suggestion shown in an [EmptyState]: a clickable pill that does something useful right away.
class EmptySuggestion {
  const EmptySuggestion(this.label, this.onTap, {this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
}

/// What to show where there is nothing yet: a rich vector graphic illustration or soft badge, a title,
/// one line of guidance, then optional action widgets (buttons) and clickable [suggestions].
/// [compact] shrinks it for narrow lists.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.graphic,
    required this.title,
    this.message,
    this.actions = const [],
    this.suggestions = const [],
    this.compact = false,
  });

  final IconData? icon;
  final Widget? graphic;
  final String title;
  final String? message;
  final List<Widget> actions;
  final List<EmptySuggestion> suggestions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: SingleChildScrollView(
        // Not the primary controller: the sidebar's scrollbar owns it.
        primary: false,
        padding: EdgeInsets.all(compact ? 14 : 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 220 : 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: compact ? 6 : 8,
            children: [
              if (graphic != null)
                Padding(
                  padding: EdgeInsets.only(bottom: compact ? 2 : 6),
                  child: graphic,
                )
              else if (icon != null)
                Padding(
                  padding: EdgeInsets.only(bottom: compact ? 2 : 6),
                  child: StateGraphic(icon: icon, compact: compact),
                ),
              T(
                title,
                size: compact ? 12.5 : 15,
                weight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
              if (message != null)
                T(
                  message!,
                  size: compact ? 11 : 12,
                  lineHeight: 1.5,
                  color: p.muted,
                  textAlign: TextAlign.center,
                ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: actions,
                  ),
                ),
              if (suggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [for (final s in suggestions) _SuggestionPill(s)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill(this.suggestion);
  final EmptySuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return HoverBuilder(
      cursor: SystemMouseCursors.click,
      onTap: suggestion.onTap,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: hovered ? p.accent.withValues(alpha: 0.12) : p.field,
          borderRadius: BorderRadius.circular(14),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hovered ? p.accent.withValues(alpha: 0.5) : p.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            if (suggestion.icon != null)
              Ico(
                suggestion.icon!,
                size: 12,
                tint: hovered ? p.accent : p.muted,
              ),
            Flexible(
              child: T(
                suggestion.label,
                size: 11.5,
                lineHeight: 1.3,
                mono: true,
                color: hovered ? p.accent : p.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
