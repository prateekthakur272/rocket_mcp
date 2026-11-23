import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// A block of a markdown document.
sealed class MdBlock {
  const MdBlock();
}

class MdHeading extends MdBlock {
  const MdHeading(this.level, this.text);
  final int level;
  final String text;
}

class MdParagraph extends MdBlock {
  const MdParagraph(this.text);
  final String text;
}

class MdCode extends MdBlock {
  const MdCode(this.code, [this.lang = '']);
  final String code;
  final String lang;
}

class MdList extends MdBlock {
  const MdList(this.items, {this.ordered = false});
  final List<String> items;
  final bool ordered;
}

class MdQuote extends MdBlock {
  const MdQuote(this.text);
  final String text;
}

class MdRule extends MdBlock {
  const MdRule();
}

class MdTable extends MdBlock {
  const MdTable(this.header, this.rows);
  final List<String> header;
  final List<List<String>> rows;
}

/// A run of inline text with one style.
class MdSpan {
  const MdSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.link,
  });
  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  final String? link;

  @override
  bool operator ==(Object other) =>
      other is MdSpan &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.code == code &&
      other.link == link;

  @override
  int get hashCode => Object.hash(text, bold, italic, code, link);

  @override
  String toString() =>
      'MdSpan($text${bold ? ' b' : ''}${italic ? ' i' : ''}'
      '${code ? ' code' : ''}${link != null ? ' ->$link' : ''})';
}

final _heading = RegExp(r'^\s{0,3}(#{1,6})\s+(.*?)\s*#*\s*$');
final _rule = RegExp(r'^\s{0,3}([-*_])(\s*\1){2,}\s*$');
final _bullet = RegExp(r'^\s*[-*+]\s+(.*)$');
final _numbered = RegExp(r'^\s*\d+[.)]\s+(.*)$');
final _fence = RegExp(r'^\s*```\s*([\w+-]*)\s*$');
final _tableSep = RegExp(r'^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$');

List<String> _cells(String line) {
  var s = line.trim();
  if (s.startsWith('|')) s = s.substring(1);
  if (s.endsWith('|')) s = s.substring(0, s.length - 1);
  return s.split('|').map((c) => c.trim()).toList();
}

bool _startsBlock(String line, String? next) =>
    line.trim().isEmpty ||
    _heading.hasMatch(line) ||
    _rule.hasMatch(line) ||
    _bullet.hasMatch(line) ||
    _numbered.hasMatch(line) ||
    _fence.hasMatch(line) ||
    line.trimLeft().startsWith('>') ||
    (line.contains('|') && next != null && _tableSep.hasMatch(next));

/// Splits markdown [source] into headings, paragraphs, lists, quotes, code blocks, rules and tables.
List<MdBlock> parseMarkdownBlocks(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final out = <MdBlock>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final next = i + 1 < lines.length ? lines[i + 1] : null;
    if (line.trim().isEmpty) {
      i++;
      continue;
    }
    final fence = _fence.firstMatch(line);
    if (fence != null) {
      final code = <String>[];
      i++;
      while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
        code.add(lines[i++]);
      }
      i++;
      out.add(MdCode(code.join('\n'), fence.group(1) ?? ''));
      continue;
    }
    final h = _heading.firstMatch(line);
    if (h != null) {
      out.add(MdHeading(h.group(1)!.length, h.group(2)!));
      i++;
      continue;
    }
    if (_rule.hasMatch(line)) {
      out.add(const MdRule());
      i++;
      continue;
    }
    if (line.trimLeft().startsWith('>')) {
      final q = <String>[];
      while (i < lines.length && lines[i].trimLeft().startsWith('>')) {
        q.add(lines[i].trimLeft().substring(1).trimLeft());
        i++;
      }
      out.add(MdQuote(q.join(' ').trim()));
      continue;
    }
    if (line.contains('|') && next != null && _tableSep.hasMatch(next)) {
      final header = _cells(line);
      final rows = <List<String>>[];
      i += 2;
      while (i < lines.length &&
          lines[i].contains('|') &&
          lines[i].trim().isNotEmpty) {
        rows.add(_cells(lines[i++]));
      }
      out.add(MdTable(header, rows));
      continue;
    }
    final isBullet = _bullet.hasMatch(line);
    if (isBullet || _numbered.hasMatch(line)) {
      final re = isBullet ? _bullet : _numbered;
      final items = <String>[];
      while (i < lines.length) {
        final m = re.firstMatch(lines[i]);
        if (m != null && !_rule.hasMatch(lines[i])) {
          items.add(m.group(1)!.trim());
          i++;
        } else if (items.isNotEmpty &&
            lines[i].startsWith(RegExp(r'\s{2,}\S')) &&
            !_bullet.hasMatch(lines[i]) &&
            !_numbered.hasMatch(lines[i])) {
          items[items.length - 1] = '${items.last} ${lines[i].trim()}';
          i++;
        } else {
          break;
        }
      }
      out.add(MdList(items, ordered: !isBullet));
      continue;
    }
    final para = <String>[line.trim()];
    i++;
    while (i < lines.length &&
        !_startsBlock(lines[i], i + 1 < lines.length ? lines[i + 1] : null)) {
      para.add(lines[i++].trim());
    }
    out.add(MdParagraph(para.join(' ')));
  }
  return out;
}

bool _wordChar(String s) => RegExp(r'[A-Za-z0-9]').hasMatch(s);

/// Splits one line of text into styled spans: `**bold**`, `*italic*`, `` `code` ``, `[text](url)` and bare URLs.
List<MdSpan> parseMarkdownInline(String s) {
  final out = <MdSpan>[];
  _inline(s, out, false, false);
  return out;
}

void _inline(String s, List<MdSpan> out, bool bold, bool italic) {
  final buf = StringBuffer();
  void flush() {
    if (buf.isEmpty) return;
    out.add(MdSpan(buf.toString(), bold: bold, italic: italic));
    buf.clear();
  }

  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '\\' && i + 1 < s.length && '\\`*_[]()#>-|'.contains(s[i + 1])) {
      buf.write(s[i + 1]);
      i += 2;
      continue;
    }
    if (c == '`') {
      final end = s.indexOf('`', i + 1);
      if (end > i + 1) {
        flush();
        out.add(MdSpan(s.substring(i + 1, end), code: true, bold: bold));
        i = end + 1;
        continue;
      }
    }
    if ((c == '*' || c == '_') && s.startsWith(c * 2, i)) {
      final end = s.indexOf(c * 2, i + 2);
      if (end > i + 2 && (c == '*' || i == 0 || !_wordChar(s[i - 1]))) {
        flush();
        _inline(s.substring(i + 2, end), out, true, italic);
        i = end + 2;
        continue;
      }
    }
    if (c == '*' || c == '_') {
      final okStart = c == '*' || i == 0 || !_wordChar(s[i - 1]);
      var end = s.indexOf(c, i + 1);
      while (end > 0 && end + 1 < s.length && s[end + 1] == c) {
        end = s.indexOf(c, end + 2);
      }
      if (okStart &&
          end > i + 1 &&
          s[i + 1] != ' ' &&
          (c == '*' || end + 1 >= s.length || !_wordChar(s[end + 1]))) {
        flush();
        _inline(s.substring(i + 1, end), out, bold, true);
        i = end + 1;
        continue;
      }
    }
    if (c == '[') {
      final m = RegExp(r'^\[([^\]]+)\]\(([^)\s]+)\)')
          .firstMatch(s.substring(i));
      if (m != null) {
        flush();
        final inner = <MdSpan>[];
        _inline(m.group(1)!, inner, bold, italic);
        for (final sp in inner) {
          out.add(
            MdSpan(
              sp.text,
              bold: sp.bold,
              italic: sp.italic,
              code: sp.code,
              link: m.group(2),
            ),
          );
        }
        i += m.group(0)!.length;
        continue;
      }
    }
    if ((c == 'h') && (i == 0 || !_wordChar(s[i - 1]))) {
      final m = RegExp(r'^https?://[^\s<>)\]]+').firstMatch(s.substring(i));
      if (m != null) {
        var url = m.group(0)!;
        while (url.length > 8 && '.,;:!?'.contains(url[url.length - 1])) {
          url = url.substring(0, url.length - 1);
        }
        flush();
        out.add(MdSpan(url, bold: bold, italic: italic, link: url));
        i += url.length;
        continue;
      }
    }
    buf.write(c);
    i++;
  }
  flush();
}

/// Renders markdown text with the app's palette; links open in the browser.
class MarkdownView extends StatefulWidget {
  const MarkdownView(this.source, {super.key});
  final String source;

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final List<TapGestureRecognizer> _taps = [];

  void _disposeTaps() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _disposeTaps();
    super.dispose();
  }

  TextSpan _span(Pal p, String text, TextStyle base) => TextSpan(
    style: base,
    children: [
      for (final s in parseMarkdownInline(text))
        TextSpan(
          text: s.text,
          recognizer: s.link == null
              ? null
              : (TapGestureRecognizer()
                  ..onTap = () => Platform.openUrl(s.link!)),
          mouseCursor: s.link == null ? null : SystemMouseCursors.click,
          style: s.code
              ? monoStyle(
                  fontSize: (base.fontSize ?? 13) - 1,
                  fontWeight: s.bold ? FontWeight.w700 : null,
                ).copyWith(backgroundColor: p.hover, letterSpacing: 0)
              : TextStyle(
                  fontWeight: s.bold ? FontWeight.w700 : null,
                  fontStyle: s.italic ? FontStyle.italic : null,
                  color: s.link != null ? p.accent : null,
                  decoration: s.link != null
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: p.accent,
                ),
        ),
    ],
  );

  Widget _text(Pal p, String text, {double size = 13, FontWeight? weight}) {
    final base = TextStyle(
      color: p.text,
      fontSize: size,
      height: 1.5,
      letterSpacing: bodyLetterSpacing,
      fontWeight: weight,
      decoration: TextDecoration.none,
    );
    final span = _span(p, text, base);
    for (final c in span.children ?? const <InlineSpan>[]) {
      final r = c is TextSpan ? c.recognizer : null;
      if (r is TapGestureRecognizer) _taps.add(r);
    }
    return Text.rich(span);
  }

  Widget _block(Pal p, MdBlock b) {
    switch (b) {
      case MdHeading():
        final size = const [22.0, 18.0, 16.0, 14.0, 13.0, 13.0][b.level - 1];
        return Padding(
          padding: EdgeInsets.only(top: b.level <= 2 ? 6 : 2),
          child: _text(p, b.text, size: size, weight: FontWeight.w700),
        );
      case MdParagraph():
        return _text(p, b.text);
      case MdCode():
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: p.hover,
            borderRadius: BorderRadius.circular(6),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: p.border),
          ),
          child: Text(
            b.code,
            style: monoStyle(fontSize: 12, color: p.text, height: 1.5),
          ),
        );
      case MdList():
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 3,
          children: [
            for (var i = 0; i < b.items.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: b.ordered ? 26 : 18,
                    child: _text(p, b.ordered ? '${i + 1}.' : '•'),
                  ),
                  Expanded(child: _text(p, b.items[i])),
                ],
              ),
          ],
        );
      case MdQuote():
        return Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: p.accent, width: 3)),
          ),
          child: _text(p, b.text),
        );
      case MdRule():
        return Container(height: 1, color: p.border);
      case MdTable():
        final cols = b.header.length;
        Widget cell(String t, bool head) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: _text(p, t, size: 12, weight: head ? FontWeight.w700 : null),
        );
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: p.border),
          ),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: p.border),
              verticalInside: BorderSide(color: p.border),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(color: p.hover),
                children: [for (final h in b.header) cell(h, true)],
              ),
              for (final r in b.rows)
                TableRow(
                  children: [
                    for (var i = 0; i < cols; i++)
                      cell(i < r.length ? r[i] : '', false),
                  ],
                ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeTaps();
    final p = context.pal;
    final blocks = parseMarkdownBlocks(widget.source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [for (final b in blocks) _block(p, b)],
    );
  }
}
