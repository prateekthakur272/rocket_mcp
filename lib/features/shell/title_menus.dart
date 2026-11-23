import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Material;
import 'package:rocket_mcp/app/title_menu_state.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/overlay.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/features/shell/menu_model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// The menu bar drawn inside the title bar (Windows / Linux), from the same [AppMenus] data the native macOS bar uses.
/// Click a title to open its menu; while one is open, moving over another title switches to it, like a native menu bar.
/// Clicking anywhere else, or pressing Esc, closes it. The open menu is drawn in the app's overlay layer, so it never blocks the bar.
class TitleMenus extends StatefulWidget {
  const TitleMenus({super.key, required this.menus, required this.tm});

  final List<MenuSpec> menus;
  final TitleMenuState tm;

  @override
  State<TitleMenus> createState() => _TitleMenusState();
}

class _TitleMenusState extends State<TitleMenus> {
  final Object _token = Object();
  final Map<String, GlobalKey> _keys = {};
  MenuOverlay? _overlay;

  TitleMenuState get tm => widget.tm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overlay = LocalMenuOverlay.of(context);
  }

  @override
  void dispose() {
    final o = _overlay;
    final t = tm;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      o?.hide(_token);
      t.close();
    });
    super.dispose();
  }

  void _syncOverlay() {
    final overlay = _overlay;
    if (overlay == null) return;
    MenuSpec? openMenu;
    for (final m in widget.menus) {
      if (m.label == tm.open) openMenu = m;
    }
    final anchor = openMenu != null ? tm.anchors[openMenu.label] : null;
    if (openMenu != null && anchor != null) {
      final rows = openMenu.items.fold<int>(
        0,
        (a, e) => a + (e is SubMenuSpec ? e.items.length + 1 : 1),
      );
      final menu = openMenu;
      overlay.show(
        _token,
        anchor.left,
        anchor.top,
        anchor.bottom,
        rows * 30.0 + 16.0,
        (ctx) => _MenuPanel(menu: menu, tm: tm),
      );
    } else {
      overlay.hide(_token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var changed = false;
      for (final m in widget.menus) {
        final box =
            _keys[m.label]?.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.attached && box.hasSize) {
          final r = box.localToGlobal(Offset.zero) & box.size;
          if (tm.anchors[m.label] != r) {
            tm.anchors[m.label] = r;
            changed = true;
          }
        }
      }
      if (changed || tm.open != null) _syncOverlay();
      if (tm.open == null) _overlay?.hide(_token);
    });
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final m in widget.menus)
          Builder(
            builder: (context) {
              final on = tm.open == m.label;
              final key = _keys.putIfAbsent(m.label, () => GlobalKey());
              return HoverBuilder(
                indicate: true,
                borderRadius: BorderRadius.circular(4),
                cursor: SystemMouseCursors.basic,
                onTap: () => tm.open = on ? null : m.label,
                builder: (ctx, hov) {
                  if (hov && tm.open != null && tm.open != m.label) {
                    SchedulerBinding.instance.addPostFrameCallback(
                      (_) => tm.open = m.label,
                    );
                  }
                  return Container(
                    key: key,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: on || hov ? p.hover : const Color(0x00000000),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: T(
                      m.label,
                      size: 12,
                      weight: on ? FontWeight.w600 : null,
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({required this.menu, required this.tm});
  final MenuSpec menu;
  final TitleMenuState tm;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: p.panel,
      elevation: 12,
      shadowColor: const Color(0xFF000000),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: _PanelBox(
        tm: tm,
        child: Container(
          width: 350,
          // Borders are painted over the content so they take no layout space.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.border, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _entries(context, menu.items, false),
          ),
        ),
      ),
    );
  }

  List<Widget> _entries(
    BuildContext context,
    List<MenuEntry> items,
    bool indent,
  ) {
    final p = context.pal;
    final out = <Widget>[];
    for (final e in items) {
      switch (e) {
        case MenuSeparator():
          out.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              height: 1,
              color: p.border,
            ),
          );
        case SubMenuSpec():
          out.add(
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 6, bottom: 2),
              child: T(
                e.label.toUpperCase(),
                color: p.muted,
                size: 10,
                weight: FontWeight.w600,
              ),
            ),
          );
          out.addAll(
            _entries(context, [
              for (final it in e.items)
                (!e.enabled && it is MenuItemSpec)
                    ? MenuItemSpec(
                        it.label,
                        shortcut: it.shortcut,
                        enabled: false,
                        checked: it.checked,
                        action: it.action,
                      )
                    : it,
            ], true),
          );
        case MenuItemSpec():
          out.add(_Item(item: e, indent: indent, tm: tm));
      }
    }
    return out;
  }
}

/// Reports its global bounds to [TitleMenuState.panel] (tells clicks inside the open menu from outside ones).
class _PanelBox extends StatelessWidget {
  const _PanelBox({required this.tm, required this.child});
  final TitleMenuState tm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.attached && box.hasSize) {
        tm.panel = box.localToGlobal(Offset.zero) & box.size;
      }
    });
    return child;
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.indent, required this.tm});
  final MenuItemSpec item;
  final bool indent;
  final TitleMenuState tm;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final e = item;
    return HoverBuilder(
      indicate: true,
      cursor: SystemMouseCursors.basic,
      onTap: e.enabled
          ? () {
              tm.close();
              e.action();
            }
          : null,
      builder: (ctx, hov) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: hov && e.enabled
            ? p.accent.withValues(alpha: 0.14)
            : const Color(0x00000000),
        child: Row(
          spacing: 8,
          children: [
            SizedBox(
              width: indent ? 30 : 16,
              child: Align(
                alignment: Alignment.centerRight,
                child: e.checked == true
                    ? Ico(Ic.check, tint: p.accent, size: 14)
                    : null,
              ),
            ),
            Expanded(
              child: T(
                e.label,
                color: e.enabled ? p.text : p.muted.withValues(alpha: 0.6),
                maxLines: 1,
              ),
            ),
            if (e.shortcut != null)
              T(
                e.shortcut!.label(false),
                color: p.muted,
                size: 11,
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }
}
