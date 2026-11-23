import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart' hide Chip;
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/syntax_highlight.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Read-only, virtualised viewer for large text such as response bodies.
class CodeView extends StatefulWidget {
  const CodeView({
    super.key,
    required this.text,
    required this.lang,
    this.wrap = true,
    this.query = '',
    this.focusLine = -1,
    this.borderRadius = const BorderRadius.all(Radius.circular(5)),
    this.bordered = true,
  });

  final String text;
  final String lang;
  final bool wrap;
  final String query;
  final int focusLine;
  final BorderRadius? borderRadius;
  final bool bordered;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  final ScrollController _sc = ScrollController();
  late List<String> _lines = codeLines(widget.text);

  // Row heights and offsets are computed up front and only visible rows are built, in one scrollable
  // of the exact total height, so the scrollbar thumb stays stable (a lazy list only estimates it).
  Float64List _offsets = Float64List(
    1,
  ); // _offsets[i] = top of row i, _offsets[n] = total
  double _layoutWidth = -1;
  bool _layoutWrap = true;
  double _layoutScale = 1;
  double? _charW;

  @override
  void initState() {
    super.initState();
    _scrollToFocus();
  }

  void _layout(double textW, TextStyle style, double scale) {
    if (_layoutWidth == textW &&
        _layoutWrap == widget.wrap &&
        _layoutScale == scale &&
        _offsets.length == _lines.length + 1) {
      return;
    }
    _layoutWidth = textW;
    _layoutWrap = widget.wrap;
    _layoutScale = scale;
    final n = _lines.length;
    final o = Float64List(n + 1);
    final rowH = 19.0 * scale;
    final cw = _charW ??=
        (TextPainter(
          text: TextSpan(text: '0' * 20, style: style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(scale),
        )..layout()).width /
        20;
    var y = 0.0;
    for (var i = 0; i < n; i++) {
      o[i] = y;
      double h = rowH;
      if (widget.wrap) {
        final line = _lines[i];
        if (line.length * cw > textW - 1) {
          final tp = TextPainter(
            text: TextSpan(text: line, style: style),
            textDirection: TextDirection.ltr,
            textScaler: TextScaler.linear(scale),
          )..layout(maxWidth: textW);
          h = math.max(rowH, tp.height);
        }
      }
      y += h;
    }
    o[n] = y;
    _offsets = o;
  }

  /// First row whose bottom is below [y].
  int _rowAt(double y) {
    var lo = 0, hi = _lines.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_offsets[mid + 1] <= y) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  @override
  void didUpdateWidget(CodeView old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _lines = codeLines(widget.text);
      _layoutWidth = -1;
    }
    if (old.focusLine != widget.focusLine || old.text != widget.text) {
      _scrollToFocus();
    }
  }

  void _scrollToFocus() {
    if (widget.focusLine < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sc.hasClients) return;
      final i = math.max(0, widget.focusLine - 3).clamp(0, _lines.length - 1);
      final to = _offsets.length > i ? _offsets[i] : i * 19.0;
      _sc.jumpTo(to.clamp(0.0, _sc.position.maxScrollExtent).toDouble());
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final base = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 13,
      height: 19 / 13,
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: bodyLetterSpacing,
      color: p.text,
      decoration: TextDecoration.none,
    );
    final numStyle = base.copyWith(color: p.muted.withValues(alpha: 0.6));
    return Container(
      clipBehavior:
          (widget.borderRadius != null &&
              widget.borderRadius != BorderRadius.zero)
          ? Clip.antiAlias
          : Clip.none,
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: widget.borderRadius,
      ),
      foregroundDecoration: widget.bordered
          ? BoxDecoration(
              borderRadius: widget.borderRadius,
              border: Border.all(color: p.border, width: 1),
            )
          : null,
      child: SelectionArea(
        child: overlayScrollbarTheme(
          Scrollbar(
            controller: _sc,
            child: LayoutBuilder(
              builder: (context, cons) {
                final textW = cons.maxWidth - 46 - 8;
                _layout(textW, base, scale);
                const pad = 6.0;
                final total = _offsets[_lines.length] + 2 * pad;
                return SingleChildScrollView(
                  controller: _sc,
                  child: SizedBox(
                    height: total,
                    child: AnimatedBuilder(
                      animation: _sc,
                      builder: (context, _) {
                        final off = _sc.hasClients ? _sc.offset : 0.0;
                        final viewH = cons.maxHeight;
                        final from = _rowAt(math.max(0, off - pad));
                        final to = _rowAt(math.max(0, off - pad) + viewH);
                        return Stack(
                          children: [
                            for (
                              var i = from;
                              i <= to && i < _lines.length;
                              i++
                            )
                              Positioned(
                                key: ValueKey(i),
                                left: 0,
                                right: 0,
                                top: pad + _offsets[i],
                                height: _offsets[i + 1] - _offsets[i],
                                child: _row(i, p, base, numStyle),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(int i, Pal p, TextStyle base, TextStyle numStyle) {
    final l = _lines[i];
    return Container(
      color: i == widget.focusLine
          ? p.accent.withValues(alpha: 0.12)
          : const Color(0x00000000),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectionContainer.disabled(
            child: SizedBox(
              width: 46,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${i + 1}',
                  textAlign: TextAlign.end,
                  style: numStyle,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text.rich(
                l.length < 20000
                    ? highlight(
                        l,
                        widget.lang,
                        p,
                        query: widget.query,
                        style: base,
                      )
                    : TextSpan(text: l, style: base),
                softWrap: widget.wrap,
                maxLines: widget.wrap ? null : 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
