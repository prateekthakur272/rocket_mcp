import 'package:material_ui/material_ui.dart' hide Chip;
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Root-level host for transient menus (autocomplete). Lives in the same tree, never blocks input outside the menu.
class MenuOverlay extends ChangeNotifier {
  Object? owner;
  double x = 0;
  double yTop = 0;
  double yBottom = 0;
  double estHeight = 0;
  WidgetBuilder? content;

  void show(
    Object token,
    double x,
    double yTop,
    double yBottom,
    double estHeight,
    WidgetBuilder content,
  ) {
    owner = token;
    this.x = x;
    this.yTop = yTop;
    this.yBottom = yBottom;
    this.estHeight = estHeight;
    this.content = content;
    notifyListeners();
  }

  void hide(Object token) {
    if (identical(owner, token)) {
      owner = null;
      content = null;
      notifyListeners();
    }
  }
}

/// Provides the [MenuOverlay] to descendants (null when absent).
class LocalMenuOverlay extends InheritedWidget {
  const LocalMenuOverlay({
    super.key,
    required this.value,
    required super.child,
  });
  final MenuOverlay? value;

  static MenuOverlay? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LocalMenuOverlay>()?.value;

  @override
  bool updateShouldNotify(LocalMenuOverlay old) => value != old.value;
}

/// Must be placed as a direct child of a [Stack] that fills the window (it positions itself to fill it).
class MenuOverlayHost extends StatelessWidget {
  const MenuOverlayHost({super.key, required this.overlay});

  final MenuOverlay overlay;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ListenableBuilder(
      listenable: overlay,
      builder: (context, _) {
        final c = overlay.content;
        if (c == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, cons) {
            final maxW = cons.maxWidth, maxH = cons.maxHeight;
            const menuW = 380.0;
            final flip =
                overlay.yBottom + overlay.estHeight > maxH &&
                overlay.yTop - overlay.estHeight > 0;
            final x = overlay.x
                .clamp(0.0, (maxW - menuW - 8).clamp(0.0, double.infinity))
                .toDouble();
            final y = flip
                ? overlay.yTop - overlay.estHeight - 4
                : overlay.yBottom + 4;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: x,
                  top: y,
                  child: Builder(builder: c),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

typedef PopupBuilder<R> = Widget Function(
  BuildContext context,
  void Function([R? value]) close,
);

class _PopupLayout extends SingleChildLayoutDelegate {
  _PopupLayout(this.anchor, this.offset, this.width);
  final Rect anchor;
  final Offset offset;
  final double? width;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: width ?? 0,
        maxWidth: width ?? constraints.maxWidth - 16,
        maxHeight: constraints.maxHeight - 16,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.left + offset.dx;
    if (x + childSize.width > size.width - 8) {
      x = size.width - 8 - childSize.width;
    }
    if (x < 8) x = 8;
    var y = anchor.bottom + offset.dy;
    if (y + childSize.height > size.height - 8) {
      final above = anchor.top - offset.dy - childSize.height;
      y = above >= 8
          ? above
          : (size.height - 8 - childSize.height).clamp(8.0, double.infinity);
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupLayout old) =>
      old.anchor != anchor || old.offset != offset || old.width != width;
}

class _PopupRoute<R> extends PopupRoute<R> {
  _PopupRoute({
    required this.anchor,
    required this.offset,
    required this.width,
    required this.radius,
    required this.builder,
    required this.themes,
    required this.pal,
  });

  final Rect anchor;
  final Offset offset;
  final double? width;
  final double radius;
  final PopupBuilder<R> builder;
  final CapturedThemes themes;
  final Pal pal;

  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Dismiss';
  @override
  Duration get transitionDuration => const Duration(milliseconds: 90);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final p = pal;
    final panel = width != null
        ? SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: builder(context, ([v]) => Navigator.of(context).pop(v)),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 280),
            child: IntrinsicWidth(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                child: builder(context, ([v]) => Navigator.of(context).pop(v)),
              ),
            ),
          );
    final body = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      // The border is painted over the content so it takes no layout space.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.border.withValues(alpha: 0.9), width: 1),
      ),
      child: panel,
    );
    return themes.wrap(
      FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: CustomSingleChildLayout(
          delegate: _PopupLayout(anchor, offset, width),
          child: body,
        ),
      ),
    );
  }
}

/// Opens a menu panel just below [anchor] (global rect). Completes with the value passed to `close`, or null when dismissed.
Future<R?> showAnchoredPopup<R>(
  BuildContext context, {
  required Rect anchor,
  required PopupBuilder<R> builder,
  double? width,
  Offset offset = Offset.zero,
  double radius = 8,
}) {
  final nav = Navigator.of(context, rootNavigator: true);
  return nav.push<R>(
    _PopupRoute<R>(
      anchor: anchor,
      offset: offset,
      width: width,
      radius: radius,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: nav.context),
      pal: context.pal,
    ),
  );
}

/// Global rect of the render box of [context].
Rect anchorRectOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Standard menu row of [Dropdown]/[ContextMenu]: 28dp tall, rounded hover highlight inset from the panel edge.
class PopupRow extends StatelessWidget {
  const PopupRow({
    super.key,
    required this.onClick,
    required this.child,
    this.danger = false,
  });
  final VoidCallback onClick;
  final Widget child;

  /// Tints the hover highlight with the error colour.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return HoverBuilder(
      cursor: SystemMouseCursors.click,
      onTap: onClick,
      builder: (ctx, hov) => Container(
        constraints: const BoxConstraints(minHeight: 28),
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: hov
              ? (danger ? p.err.withValues(alpha: 0.15) : p.hover)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(5),
        ),
        child: child,
      ),
    );
  }
}

/// Dropdown selector that opens a menu below the field.
class Dropdown extends StatelessWidget {
  const Dropdown({
    super.key,
    required this.selected,
    required this.options,
    required this.onSelect,
    this.color,
    this.weight,
    this.optionColor,
    this.bordered = true,
    this.expand = false,
  });

  /// Fill the available width instead of fitting the selected text.
  final bool expand;

  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelect;
  final Color? color;
  final FontWeight? weight;

  /// Per-option text colour; null (or a null result) means the default text colour.
  final Color? Function(String)? optionColor;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Builder(
      builder: (anchorCtx) {
        return Clickable(
          onClick: () async {
            final v = await showAnchoredPopup<String>(
              anchorCtx,
              anchor: anchorRectOf(anchorCtx),
              builder: (ctx, close) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final o in options)
                    PopupRow(
                      onClick: () => close(o),
                      child: T(
                        o,
                        color: optionColor?.call(o) ?? p.text,
                        weight: o == selected ? FontWeight.w600 : null,
                      ),
                    ),
                ],
              ),
            );
            if (v != null) onSelect(v);
          },
          cursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: CONTROL_H,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: bordered
                ? BoxDecoration(
                    color: p.field,
                    borderRadius: BorderRadius.circular(5),
                  )
                : null,
            // Border is painted over the content so it doesn't change the layout.
            foregroundDecoration: bordered
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: p.border, width: 1),
                  )
                : null,
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              spacing: 6,
              children: [
                Flexible(
                  fit: expand ? FlexFit.tight : FlexFit.loose,
                  child: T(
                    selected,
                    color: color ?? p.text,
                    weight: weight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Ico(Ic.dropDown, tint: p.muted, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
