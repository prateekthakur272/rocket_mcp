// ignore_for_file: constant_identifier_names
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart' hide Chip;
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/overlay.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Names of the variables known in the current scope (drives the green/red `{{var}}` highlighting).
class LocalVars extends InheritedWidget {
  const LocalVars({super.key, required this.value, required super.child});
  final Set<String> value;

  static Set<String> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocalVars>()?.value ??
      const <String>{};

  @override
  bool updateShouldNotify(LocalVars old) => value != old.value;
}

class VarInfo {
  const VarInfo(this.value, this.source);
  final String value;
  final String source;
}

class LocalVarInfo extends InheritedWidget {
  const LocalVarInfo({super.key, required this.value, required super.child});
  final Map<String, VarInfo> value;

  static Map<String, VarInfo> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocalVarInfo>()?.value ??
      const <String, VarInfo>{};

  @override
  bool updateShouldNotify(LocalVarInfo old) => value != old.value;
}

/// Names usable as single-brace `{name}` (values a workflow passes on), with what to show beside each.
class LocalFlowVars extends InheritedWidget {
  const LocalFlowVars({super.key, required this.value, required super.child});
  final Set<String> value;

  static Set<String> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocalFlowVars>()?.value ??
      const <String>{};

  @override
  bool updateShouldNotify(LocalFlowVars old) => value != old.value;
}

class LocalFlowInfo extends InheritedWidget {
  const LocalFlowInfo({super.key, required this.value, required super.child});
  final Map<String, VarInfo> value;

  static Map<String, VarInfo> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocalFlowInfo>()?.value ??
      const <String, VarInfo>{};

  @override
  bool updateShouldNotify(LocalFlowInfo old) => value != old.value;
}

final RegExp _flowRe = RegExp(
  r'(?<!\{)\{([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z0-9_\[\]-]+)*)\}',
);
final RegExp _varRe = RegExp(r'\{\{\s*([^{}]+?)\s*\}\}');

/// Colours `{{variable}}` references green (known) or red (unknown), and `{name}` values a workflow passes on.
class VarTransform {
  VarTransform(this.pal, this.known, [this.flow = const {}]);
  final Pal pal;
  final Set<String> known;
  final Set<String> flow;

  TextSpan filter(String text, TextStyle style) {
    if (!text.contains('{{') && (flow.isEmpty || !text.contains('{'))) {
      return TextSpan(text: text, style: style);
    }
    final ranges = <StyleRange>[];
    if (flow.isNotEmpty) {
      for (final m in _flowRe.allMatches(text)) {
        final name = m.group(1)!;
        final dot = name.indexOf('.');
        if (flow.contains(dot < 0 ? name : name.substring(0, dot))) {
          ranges.add(StyleRange(m.start, m.end, color: pal.accent, bold: true));
        }
      }
    }
    for (final m in _varRe.allMatches(text)) {
      final n = m.group(1)!;
      final ok =
          known.contains(n) ||
          n.startsWith(r'$') ||
          n.startsWith('process.env.') ||
          (n.contains('.') && known.contains(n.substring(0, n.indexOf('.'))));
      ranges.add(
        StyleRange(m.start, m.end, color: ok ? pal.ok : pal.err, bold: true),
      );
    }
    return buildStyledSpan(text, style, ranges);
  }
}

const List<String> DYNAMIC_VARS = [
  r'$guid',
  r'$timestamp',
  r'$isoTimestamp',
  r'$randomInt',
  r'$randomUUID',
  r'$randomEmail',
  r'$randomBoolean',
  r'$randomFirstName',
  r'$randomLastName',
];

final RegExp _varPrefixRe = RegExp(r'\{\{\s*([\w.$-]*)$');
final RegExp _flowPrefixRe = RegExp(r'(?<!\{)\{([\w.]*)$');

const Map<String, String> _dynamicHints = {
  r'$guid': 'Random UUID',
  r'$randomUUID': 'Random UUID',
  r'$timestamp': 'Unix time in seconds',
  r'$isoTimestamp': 'ISO-8601 date-time',
  r'$randomInt': 'Random number 0–999',
  r'$randomEmail': 'Random email address',
  r'$randomBoolean': 'true or false',
  r'$randomFirstName': 'Random first name',
  r'$randomLastName': 'Random last name',
};

class Sug {
  const Sug(this.text, this.detail, this.tag, this.isVar);
  final String text;
  final String? detail;
  final String? tag;
  final bool isVar;
}

class _HlController extends TextEditingController {
  Pal? pal;
  Set<String> known = const {};
  Set<String> flow = const {};
  bool highlight = false;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!highlight || pal == null || style == null) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return VarTransform(pal!, known, flow).filter(text, style);
  }
}

String _take(String s, int n) => s.length <= n ? s : s.substring(0, n);

int _cmpSug(String a, String b) {
  final ad = a.contains('.'), bd = b.contains('.');
  if (ad != bd) return ad ? 1 : -1;
  return a.compareTo(b);
}

/// Single-line text field with `{{variable}}` highlighting and autocomplete.
class Field extends StatefulWidget {
  const Field({
    super.key,
    required this.value,
    required this.onChange,
    this.placeholder = '',
    this.mono = false,
    this.password = false,
    this.bordered = true,
    this.onEnter,
    this.focusRequester,
    this.highlightVars = true,
    this.suggestions = const [],
    this.hints,
  });

  final String value;
  final ValueChanged<String> onChange;
  final String placeholder;
  final bool mono;
  final bool password;
  final bool bordered;
  final VoidCallback? onEnter;

  /// A focus node the caller can use to focus the field.
  final FocusNode? focusRequester;
  final bool highlightVars;
  final List<String> suggestions;
  final String? Function(String)? hints;

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  final _HlController _ctl = _HlController();
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusRequester ?? (_ownFocus ??= FocusNode());
  FocusNode? _attached;
  bool focused = false;
  int selIdx = 0;
  int dismissedAt = -1;
  bool _syncing = false;
  final Object _token = Object();
  MenuOverlay? _overlay;
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _ctl.text = widget.value;
    _lastText = widget.value;
    _ctl.addListener(_onCtl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overlay = LocalMenuOverlay.of(context);
    _attachFocus();
  }

  void _attachFocus() {
    final f = _focus;
    if (identical(f, _attached)) return;
    _attached?.removeListener(_onFocus);
    _attached = f;
    f.addListener(_onFocus);
    focused = f.hasFocus;
  }

  void _onFocus() {
    if (!mounted) return;
    if (focused != _focus.hasFocus) setState(() => focused = _focus.hasFocus);
  }

  void _onCtl() {
    if (_syncing || !mounted) return;
    final t = _ctl.text;
    setState(() {
      selIdx = 0;
    });
    if (t != _lastText) {
      _lastText = t;
      if (t != widget.value) widget.onChange(t);
      // a parent that did not accept the edit shows its own value again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _ctl.text != widget.value) {
          _setValue(widget.value, widget.value.length);
        }
      });
    }
  }

  void _setValue(String text, int caret) {
    _syncing = true;
    _ctl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret.clamp(0, text.length)),
    );
    _lastText = text;
    _syncing = false;
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(Field old) {
    super.didUpdateWidget(old);
    if (_ctl.text != widget.value) {
      _syncing = true;
      _ctl.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
      _lastText = widget.value;
      _syncing = false;
    }
    _attachFocus();
  }

  @override
  void dispose() {
    _attached?.removeListener(_onFocus);
    _ownFocus?.dispose();
    _ctl.dispose();
    final o = _overlay;
    if (o != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => o.hide(_token));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final known = LocalVars.of(context);
    final varInfo = LocalVarInfo.of(context);
    final flowNames = LocalFlowVars.of(context);
    final flowInfo = LocalFlowInfo.of(context);
    final style = TextStyle(
      color: p.text,
      fontSize: 13,
      height: 18 / 13,
      fontFamily: widget.mono ? monoFamily : null,
      fontFamilyFallback: widget.mono ? monoFallback : null,
    );
    _ctl.pal = p;
    _ctl.known = known;
    _ctl.flow = flowNames;
    _ctl.highlight = widget.highlightVars && !widget.password;

    final text = _ctl.text;
    final sel = _ctl.selection;
    final cursor = (sel.isValid ? sel.end : text.length).clamp(0, text.length);
    final collapsed = !sel.isValid || sel.isCollapsed;
    final password = widget.password;
    final highlightVars = widget.highlightVars;

    RegExpMatch? match;
    if (highlightVars &&
        !password &&
        focused &&
        collapsed &&
        dismissedAt != cursor) {
      match = _varPrefixRe.firstMatch(text.substring(0, cursor));
    }
    var varSugg = <String>[];
    if (match != null) {
      final q = match.group(1)!;
      final ql = q.toLowerCase();
      varSugg =
          {
              ...known,
              ...DYNAMIC_VARS,
            }.where((s) => s.toLowerCase().startsWith(ql) && s != q).toList()
            ..sort(_cmpSug);
      varSugg = varSugg.take(12).toList();
    }
    final isVar = varSugg.isNotEmpty;
    // single brace: values a workflow passed on, completed from `{`
    RegExpMatch? fmatch;
    if (!isVar &&
        match == null &&
        flowNames.isNotEmpty &&
        highlightVars &&
        !password &&
        focused &&
        collapsed &&
        dismissedAt != cursor) {
      fmatch = _flowPrefixRe.firstMatch(text.substring(0, cursor));
    }
    var flowSugg = <String>[];
    if (fmatch != null) {
      final ql = fmatch.group(1)!.toLowerCase();
      flowSugg =
          flowNames
              .where(
                (s) => s.toLowerCase().startsWith(ql) && s != fmatch!.group(1),
              )
              .toList()
            ..sort(_cmpSug);
      flowSugg = flowSugg.take(12).toList();
    }
    final isFlow = flowSugg.isNotEmpty;
    var textSugg = <String>[];
    if (!isVar &&
        !isFlow &&
        widget.suggestions.isNotEmpty &&
        focused &&
        !password &&
        dismissedAt != cursor) {
      final q = text.trim();
      final ql = q.toLowerCase();
      textSugg = widget.suggestions
          .where((s) => s.toLowerCase().contains(ql) && s != q)
          .take(8)
          .toList();
    }
    final sugg = isVar ? varSugg : (isFlow ? flowSugg : textSugg);

    void accept(String name) {
      if (isFlow) {
        final m = fmatch;
        if (m == null) return;
        var rest = text.substring(cursor);
        if (rest.startsWith('}')) rest = rest.substring(1);
        final nt = '${text.substring(0, m.start)}{$name}$rest';
        _setValue(nt, m.start + name.length + 2);
        widget.onChange(nt);
        return;
      }
      if (!isVar) {
        _setValue(name, name.length);
        widget.onChange(name);
        dismissedAt = name.length;
        return;
      }
      final m = match;
      if (m == null) return;
      var rest = text.substring(cursor);
      if (rest.startsWith('}}')) rest = rest.substring(2);
      final nt = '${text.substring(0, m.start)}{{$name}}$rest';
      _setValue(nt, m.start + name.length + 4);
      widget.onChange(nt);
    }

    final selNow = sugg.isEmpty
        ? 0
        : selIdx.clamp(0, math.max(0, sugg.length - 1)).toInt();

    // Keep the autocomplete menu in sync.
    final overlay = _overlay;
    if (overlay != null) {
      final menuItems = <Sug>[];
      for (final n in sugg) {
        if (isFlow) {
          menuItems.add(
            Sug(
              n,
              flowInfo[n] == null ? null : _take(flowInfo[n]!.value, 70),
              flowInfo[n]?.source,
              true,
            ),
          );
        } else if (isVar) {
          final vi = varInfo[n];
          menuItems.add(
            Sug(
              n,
              _dynamicHints[n] ?? (vi == null ? null : _take(vi.value, 70)),
              n.startsWith(r'$') ? 'dynamic' : vi?.source,
              true,
            ),
          );
        } else {
          menuItems.add(Sug(n, widget.hints?.call(n), null, false));
        }
      }
      final q = isVar
          ? (match?.group(1) ?? '')
          : (isFlow ? (fmatch?.group(1) ?? '') : text.trim());
      final title = isFlow
          ? 'Passed-on values'
          : (isVar ? 'Variables' : 'Suggestions');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (sugg.isNotEmpty) {
          final rb = context.findRenderObject();
          if (rb is! RenderBox || !rb.hasSize) return;
          final pos = rb.localToGlobal(Offset.zero);
          final est = math.min(sugg.length, 7) * 40.0 + 64.0;
          overlay.show(_token, pos.dx, pos.dy, pos.dy + rb.size.height, est, (
            ctx,
          ) {
            return SuggestionMenu(
              items: menuItems,
              selected: selNow,
              query: q,
              title: title,
              onPick: (i) => accept(sugg[i]),
              onHover: (i) {
                if (mounted && selIdx != i) setState(() => selIdx = i);
              },
            );
          });
        } else {
          overlay.hide(_token);
        }
      });
    }

    KeyEventResult onKey(FocusNode node, KeyEvent e) {
      if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      final k = e.logicalKey;
      if (sugg.isNotEmpty) {
        if (k == LogicalKeyboardKey.arrowDown) {
          setState(() => selIdx = (selIdx + 1) % sugg.length);
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowUp) {
          setState(() => selIdx = (selIdx - 1 + sugg.length) % sugg.length);
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.numpadEnter ||
            k == LogicalKeyboardKey.tab) {
          accept(sugg[selIdx.clamp(0, sugg.length - 1).toInt()]);
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.escape) {
          setState(() => dismissedAt = cursor);
          return KeyEventResult.handled;
        }
      }
      if (widget.onEnter != null &&
          (k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.numpadEnter) &&
          !HardwareKeyboard.instance.isMetaPressed &&
          !HardwareKeyboard.instance.isControlPressed) {
        widget.onEnter!();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: onKey,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.bordered ? p.field : const Color(0x00000000),
          borderRadius: BorderRadius.circular(5),
        ),
        // Border is painted over the content so it doesn't change the layout.
        foregroundDecoration: widget.bordered
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: p.border, width: 1),
              )
            : null,
        constraints: const BoxConstraints(minHeight: CONTROL_H),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: _ctl,
          focusNode: _focus,
          style: style,
          cursorColor: p.accent,
          cursorRadius: Radius.zero,
          cursorOpacityAnimates: false,
          maxLines: 1,
          obscureText: widget.password,
          autocorrect: false,
          enableSuggestions: false,
          onTapOutside: (_) {},
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            hintText: widget.placeholder,
            hintStyle: style.copyWith(
              color: p.muted.withValues(alpha: 0.7),
              letterSpacing: bodyLetterSpacing,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
      ),
    );
  }
}

class SuggestionMenu extends StatefulWidget {
  const SuggestionMenu({
    super.key,
    required this.items,
    required this.selected,
    required this.query,
    required this.title,
    required this.onPick,
    required this.onHover,
  });

  final List<Sug> items;
  final int selected;
  final String query;
  final String title;
  final ValueChanged<int> onPick;
  final ValueChanged<int> onHover;

  @override
  State<SuggestionMenu> createState() => _SuggestionMenuState();
}

class _SuggestionMenuState extends State<SuggestionMenu> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(SuggestionMenu old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final to = math
            .max(0.0, (widget.selected - 3) * 40.0)
            .clamp(0.0, _scroll.position.maxScrollExtent)
            .toDouble();
        _scroll.animateTo(
          to,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = widget.items;
    // The border is painted over the content so it adds no layout inset.
    return SizedBox(
      width: 380,
      child: Material(
        color: p.panel,
        elevation: 12,
        shadowColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: p.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: p.hover.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: T(
                      widget.title.toUpperCase(),
                      color: p.muted,
                      size: 10,
                      weight: FontWeight.w600,
                    ),
                  ),
                  T('${items.length}', color: p.muted, size: 10),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 288),
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++) _row(p, i, items[i]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                spacing: 14,
                children: [
                  T('↑↓ move', color: p.muted, size: 10),
                  T('↵ / Tab insert', color: p.muted, size: 10),
                  T('esc dismiss', color: p.muted, size: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(Pal p, int i, Sug it0) {
    final sel = i == widget.selected;
    final q = widget.query;
    final at = q.isEmpty ? -1 : it0.text.toLowerCase().indexOf(q.toLowerCase());
    const mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 13,
      height: 17 / 13,
      letterSpacing: bodyLetterSpacing,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final base = mono.copyWith(color: p.text);
    final label = at >= 0
        ? TextSpan(
            style: base,
            children: [
              TextSpan(text: it0.text.substring(0, at)),
              TextSpan(
                text: it0.text.substring(at, at + q.length),
                style: TextStyle(color: p.accent, fontWeight: FontWeight.w700),
              ),
              TextSpan(text: it0.text.substring(at + q.length)),
            ],
          )
        : TextSpan(text: it0.text, style: base);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHover(i),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onPick(i),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: sel
                ? p.accent.withValues(alpha: 0.14)
                : const Color(0x00000000),
          ),
          // The 3dp accent bar is drawn over the row and does not push the content.
          foregroundDecoration: sel
              ? BoxDecoration(
                  border: Border(left: BorderSide(color: p.accent, width: 3)),
                )
              : null,
          child: Row(
            spacing: 10,
            children: [
              Ico(
                it0.isVar ? Ic.variables : Ic.key,
                tint: it0.isVar
                    ? (it0.text.startsWith(r'$') ? p.syntaxKeyword : p.ok)
                    : p.accent,
                size: 17,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (it0.detail != null && it0.detail!.isNotEmpty)
                      Text(
                        it0.detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.muted,
                          fontSize: 11,
                          height: 14 / 11,
                          letterSpacing: bodyLetterSpacing,
                          leadingDistribution: TextLeadingDistribution.even,
                          decoration: TextDecoration.none,
                        ),
                      ),
                  ],
                ),
              ),
              if (it0.tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: p.muted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: T(it0.tag!, color: p.muted, size: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multi-line plain text box. [minHeight] sets the minimum height; [expands] fills the space it is given.
class AreaField extends StatefulWidget {
  const AreaField({
    super.key,
    required this.value,
    required this.onChange,
    this.placeholder = '',
    this.mono = true,
    this.minHeight = 0,
    this.expands = false,
    this.maxLines,
  });

  final String value;
  final ValueChanged<String> onChange;
  final String placeholder;
  final bool mono;
  final double minHeight;
  final bool expands;

  /// Grows with the text up to this many lines, then scrolls; null grows without limit.
  final int? maxLines;

  @override
  State<AreaField> createState() => _AreaFieldState();
}

class _AreaFieldState extends State<AreaField> {
  late final TextEditingController _c = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(AreaField old) {
    super.didUpdateWidget(old);
    if (_c.text != widget.value) {
      _c.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final style = TextStyle(
      color: p.text,
      fontSize: 13,
      height: 18 / 13,
      fontFamily: widget.mono ? monoFamily : null,
      fontFamilyFallback: widget.mono ? monoFallback : null,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(minHeight: widget.minHeight),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(5),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: p.border, width: 1),
      ),
      child: TextField(
        controller: _c,
        style: style,
        cursorColor: p.accent,
        cursorRadius: Radius.zero,
        cursorOpacityAnimates: false,
        maxLines: widget.expands ? null : widget.maxLines,
        expands: widget.expands,
        textAlignVertical: TextAlignVertical.top,
        autocorrect: false,
        enableSuggestions: false,
        onTapOutside: (_) {},
        onChanged: (t) {
          if (t != widget.value) widget.onChange(t);
        },
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
          hintText: widget.placeholder,
          hintStyle: style.copyWith(
            color: p.muted.withValues(alpha: 0.7),
            letterSpacing: bodyLetterSpacing,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}
