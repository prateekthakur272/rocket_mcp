import 'package:material_ui/material_ui.dart' hide Chip;
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/json.dart';

class _TreeNode {
  _TreeNode(this.id, this.key, this.value, this.depth, this.path);
  final String id;
  final String? key;
  final dynamic value;
  final int depth;
  final String path;
  bool get container => value is Map || value is List;
  int get size => value is Map
      ? (value as Map).length
      : (value is List ? (value as List).length : 0);
}

final RegExp _identRe = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

String _childPath(String parent, Object? key, bool isIndex) {
  if (isIndex) return '$parent[$key]';
  if (_identRe.hasMatch(key.toString())) return '$parent.$key';
  return "$parent['$key']";
}

List<_TreeNode> _flatten(dynamic root, Set<String> expanded) {
  final out = <_TreeNode>[];
  void walk(String? key, dynamic v, int depth, String path) {
    out.add(_TreeNode(path, key, v, depth, path));
    if (expanded.contains(path)) {
      if (v is Map) {
        v.forEach(
          (k, x) =>
              walk(k.toString(), x, depth + 1, _childPath(path, k, false)),
        );
      } else if (v is List) {
        for (var i = 0; i < v.length; i++) {
          walk('$i', v[i], depth + 1, _childPath(path, i, true));
        }
      }
    }
  }

  walk(null, root, 0, r'$');
  return out;
}

Set<String> _allContainers(dynamic root, [int limit = 5000]) {
  final ids = <String>{};
  void walk(dynamic v, String path) {
    if (ids.length > limit) return;
    if (v is Map) {
      ids.add(path);
      v.forEach((k, x) => walk(x, _childPath(path, k, false)));
    } else if (v is List) {
      ids.add(path);
      for (var i = 0; i < v.length; i++) {
        walk(v[i], _childPath(path, i, true));
      }
    }
  }

  walk(root, r'$');
  return ids;
}

/// Collapsible JSON viewer. [expandSignal] > 0 expands everything, < 0 collapses (changes force a re-apply).
class JsonTree extends StatefulWidget {
  const JsonTree({
    super.key,
    required this.root,
    this.expandSignal = 0,
    required this.onCopy,
  });

  final dynamic root;
  final int expandSignal;
  final void Function(String, String) onCopy;

  @override
  State<JsonTree> createState() => _JsonTreeState();
}

class _JsonTreeState extends State<JsonTree> {
  late Set<String> expanded;
  final ScrollController _sc = ScrollController();

  Set<String> _initial() => _allContainers(widget.root, 400)
      .where((s) => s.split('').where((c) => c == '.' || c == '[').length <= 1)
      .toSet();

  void _apply() {
    if (widget.expandSignal > 0) {
      expanded = _allContainers(widget.root);
    } else if (widget.expandSignal < 0) {
      expanded = {r'$'};
    }
  }

  @override
  void initState() {
    super.initState();
    expanded = _initial();
    _apply();
  }

  @override
  void didUpdateWidget(JsonTree old) {
    super.didUpdateWidget(old);
    if (!identical(old.root, widget.root)) expanded = _initial();
    if (old.expandSignal != widget.expandSignal ||
        !identical(old.root, widget.root)) {
      _apply();
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final rows = _flatten(widget.root, expanded);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(5),
      ),
      // Border is painted over the content so it doesn't change the layout.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: p.border, width: 1),
      ),
      child: overlayScrollbarTheme(
        Scrollbar(
          controller: _sc,
          child: ListView.builder(
            controller: _sc,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemExtent: 24,
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final n = rows[i];
              final open = expanded.contains(n.id);
              return HoverBuilder(
                key: ValueKey(n.id),
                cursor: MouseCursor.defer,
                onTap: n.container
                    ? () => setState(
                        () => open ? expanded.remove(n.id) : expanded.add(n.id),
                      )
                    : null,
                indicate: true,
                builder: (ctx, hov) => Container(
                  color: hov
                      ? p.hover.withValues(alpha: 0.5)
                      : const Color(0x00000000),
                  padding: EdgeInsets.only(left: 8.0 + n.depth * 16, right: 6),
                  child: Row(
                    spacing: 4,
                    children: [
                      if (n.container)
                        Chevron(open: open)
                      else
                        const SizedBox(width: 14),
                      if (n.key != null) ...[
                        T(
                          n.key!,
                          color: p.syntaxKey,
                          mono: true,
                          size: 12,
                          maxLines: 1,
                        ),
                        T(':', color: p.muted, mono: true, size: 12),
                      ],
                      ..._valueWidgets(p, n, open),
                      const Spacer(),
                      if (hov) ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: T(
                            n.path,
                            color: p.muted.withValues(alpha: 0.7),
                            mono: true,
                            size: 10,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconBtn(
                          icon: Ic.link,
                          onClick: () => widget.onCopy(n.path, 'Copied path'),
                          size: 13,
                        ),
                        IconBtn(
                          icon: Ic.copy,
                          onClick: () => widget.onCopy(
                            n.value is String
                                ? n.value as String
                                : Json.stringify(n.value, pretty: true),
                            'Copied value',
                          ),
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _valueWidgets(Pal p, _TreeNode n, bool open) {
    final v = n.value;
    if (v is Map) {
      return [
        T(
          open ? '{' : '{ … }  ${n.size} ${n.size == 1 ? "key" : "keys"}',
          color: p.muted,
          mono: true,
          size: 12,
        ),
      ];
    }
    if (v is List) {
      return [
        T(
          open ? '[' : '[ … ]  ${n.size} ${n.size == 1 ? "item" : "items"}',
          color: p.muted,
          mono: true,
          size: 12,
        ),
      ];
    }
    if (v is String) {
      return [
        Flexible(
          child: T(
            '"${v.replaceAll("\n", "⏎")}"',
            color: p.syntaxString,
            mono: true,
            size: 12,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ];
    }
    if (v is bool || v == null) {
      return [
        T(
          v?.toString() ?? 'null',
          color: p.syntaxKeyword,
          mono: true,
          size: 12,
        ),
      ];
    }
    return [
      T(
        Json.str(v) ?? v.toString(),
        color: p.syntaxNumber,
        mono: true,
        size: 12,
      ),
    ];
  }
}
