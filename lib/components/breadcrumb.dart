import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// One step of a [Breadcrumb]. A step with an [onTap] is clickable; the last step is drawn as the current location.
class Crumb {
  const Crumb(this.label, {this.icon, this.onTap});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// A path of steps separated by chevrons, such as `Server › Tools › get_weather`. It shrinks with ellipses when the
/// space is short: the last step keeps the space it needs first.
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({super.key, required this.crumbs});
  final List<Crumb> crumbs;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        for (var i = 0; i < crumbs.length; i++) ...[
          if (i > 0) Ico(Ic.chevronRight, tint: p.muted, size: 14),
          Flexible(
            flex: i == crumbs.length - 1 ? 3 : 1,
            child: _CrumbView(
              crumb: crumbs[i],
              current: i == crumbs.length - 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _CrumbView extends StatelessWidget {
  const _CrumbView({required this.crumb, required this.current});
  final Crumb crumb;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return HoverBuilder(
      cursor: crumb.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onTap: crumb.onTap,
      builder: (context, hovered) {
        final clickable = crumb.onTap != null;
        final color = current
            ? p.text
            : (hovered && clickable ? p.text : p.muted);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: hovered && clickable ? p.hover : const Color(0x00000000),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              if (crumb.icon != null) Ico(crumb.icon!, tint: color, size: 14),
              Flexible(
                child: T(
                  crumb.label,
                  color: color,
                  size: 12.5,
                  weight: current ? FontWeight.w600 : FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
