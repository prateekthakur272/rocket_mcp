import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' hide Chip;
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/theme.dart';

final RegExp _jsonRe = RegExp(
  r'"(?:\\.|[^"\\])*"(\s*:)?|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|\b(?:true|false|null)\b',
);

final RegExp _xmlRe = RegExp(
  r'<!--.*?-->|</?[A-Za-z_][\w:.-]*|/?>|\s[\w:.-]+(?==)|"[^"]*"|'
  "'[^']*'",
);

final RegExp _jsRe = RegExp(
  r'''//.*|/\*.*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`[^`]*`|\b\d+(?:\.\d+)?\b|\b(?:const|let|var|function|return|if|else|for|while|await|async|new|try|catch|throw|true|false|null|undefined|typeof|of|in|class|import|from|switch|case|break|default)\b''',
);

final RegExp varRe = RegExp(r'\{\{\s*([^{}]+?)\s*\}\}');

class _LangSpec {
  const _LangSpec(
    this.kw, {
    this.line = const ['//'],
    this.block = true,
    this.triple = false,
    this.backtick = false,
    this.dollarVar = false,
    this.flags = false,
    this.cmdlet = false,
    this.types = true,
  });
  final String kw;
  final List<String> line;
  final bool block;
  final bool triple;
  final bool backtick;
  final bool dollarVar;
  final bool flags;
  final bool cmdlet;
  final bool types;
}

final Map<String, RegExp> _langs = () {
  const specs = <String, _LangSpec>{
    'py': _LangSpec(
      'import|from|as|def|class|return|if|else|elif|for|while|in|not|and|or|is|None|True|False|with|try|except|finally|raise|lambda|yield|pass|print',
      line: ['#'],
      block: false,
      triple: true,
    ),
    'java': _LangSpec(
      'import|package|public|private|protected|static|final|class|new|void|return|if|else|for|while|try|catch|throw|throws|var|int|long|boolean|null|true|false|extends|implements|interface|this',
    ),
    'kt': _LangSpec(
      'val|var|fun|class|object|import|package|return|if|else|for|while|try|catch|throw|null|true|false|when|is|in|as|it|override|private|public|internal|data|use',
      triple: true,
    ),
    'go': _LangSpec(
      'package|import|func|var|const|type|struct|interface|return|if|else|for|range|go|defer|nil|true|false|map|chan|select|switch|case|default',
      backtick: true,
    ),
    'php': _LangSpec(
      'function|return|echo|if|else|foreach|as|new|class|true|false|null|array|use|curl_init|curl_exec',
      line: ['//', '#'],
      dollarVar: true,
    ),
    'cs': _LangSpec(
      'using|namespace|var|new|await|async|return|if|else|foreach|in|class|public|private|static|void|string|int|bool|null|true|false|try|catch|throw',
    ),
    'rb': _LangSpec(
      'require|def|end|class|module|return|if|else|elsif|unless|do|while|puts|nil|true|false|begin|rescue',
      line: ['#'],
      block: false,
    ),
    'swift': _LangSpec(
      'import|let|var|func|class|struct|return|if|else|guard|for|in|while|nil|true|false|try|catch|throw|as',
      triple: true,
    ),
    'rs': _LangSpec(
      'let|mut|fn|use|mod|struct|enum|impl|pub|return|if|else|match|for|in|while|loop|async|await|true|false|self|Self',
    ),
    'dart': _LangSpec(
      'import|void|main|async|await|final|var|const|class|return|if|else|for|while|null|true|false|new',
    ),
    'ps': _LangSpec(
      'function|if|else|foreach|in|return|param|true|false|null',
      line: ['#'],
      block: false,
      dollarVar: true,
      flags: true,
      cmdlet: true,
      types: false,
    ),
    'graphql': _LangSpec(
      'query|mutation|subscription|fragment|on|true|false|null|schema|type|input|enum|interface|union|scalar|extend|directive|implements|repeatable',
      line: ['#'],
      block: false,
      triple: true,
      dollarVar: true,
    ),
    'sh': _LangSpec(
      'curl|wget|http|https|echo|export',
      line: ['#'],
      block: false,
      dollarVar: true,
      flags: true,
      types: false,
    ),
  };
  return specs.map((k, sp) {
    final comment = [
      ...sp.line.map((it) => '${RegExp.escape(it)}.*'),
      if (sp.block) r'/\*[\s\S]*?\*/',
    ].join('|');
    final str = [
      if (sp.triple) ...[r'"""[\s\S]*?"""', r"'''[\s\S]*?'''"],
      r'"(?:\\.|[^"\\])*"',
      r"'(?:\\.|[^'\\])*'",
      if (sp.backtick) r'`[^`]*`',
    ].join('|');
    final parts = <String>['(?<c>$comment)', '(?<s>$str)'];
    if (sp.dollarVar) parts.add(r'(?<v>\$\{[^}]*\}|\$[A-Za-z_]\w*)');
    parts.add(r'(?<n>\b\d+(?:\.\d+)?\b)');
    if (sp.cmdlet) parts.add(r'(?<k2>\b[A-Z][a-z]+-[A-Z][A-Za-z]+\b)');
    parts.add('(?<k>\\b(?:${sp.kw})\\b)');
    if (sp.flags) parts.add(r'(?<f>(?<=\s)--?[A-Za-z][\w-]*)');
    if (sp.types) parts.add(r'(?<t>\b[A-Z][A-Za-z0-9_]*\b)');
    return MapEntry(k, RegExp(parts.join('|')));
  });
}();

/// Syntax-highlights [text] for [lang]: `{{variables}}` (green when [known], red otherwise) and [query] matches included.
TextSpan highlight(
  String text,
  String lang,
  Pal p, {
  Set<String> known = const {},
  String query = '',
  TextStyle? style,
}) {
  final r = <StyleRange>[];
  void span(int s, int e, Color c, [bool bold = false]) =>
      r.add(StyleRange(s, e, color: c, bold: bold));
  final re = _langs[lang];
  if (re != null) {
    for (final m in re.allMatches(text)) {
      bool has(String n) {
        try {
          return m.namedGroup(n) != null;
        } catch (_) {
          return false; // group absent in this language
        }
      }

      if (has('c')) {
        span(m.start, m.end, p.syntaxComment);
      } else if (has('s')) {
        span(m.start, m.end, p.syntaxString);
      } else if (has('v') || has('n')) {
        span(m.start, m.end, p.syntaxNumber);
      } else if (has('k') || has('k2')) {
        span(m.start, m.end, p.syntaxKeyword);
      } else if (has('f') || has('t')) {
        span(m.start, m.end, p.syntaxKey);
      }
    }
  }
  switch (lang) {
    case 'json':
      for (final m in _jsonRe.allMatches(text)) {
        final s = m.group(0)!;
        if (s.startsWith('"')) {
          if (m.group(1) != null) {
            var e = s.length;
            while (e > 0 && (s[e - 1] == ':' || s[e - 1] == ' ')) {
              e--;
            }
            span(m.start, m.start + e, p.syntaxKey);
          } else {
            span(m.start, m.end, p.syntaxString);
          }
        } else if (RegExp(r'[0-9]').hasMatch(s[0]) || s[0] == '-') {
          span(m.start, m.end, p.syntaxNumber);
        } else {
          span(m.start, m.end, p.syntaxKeyword);
        }
      }
      break;
    case 'xml':
    case 'html':
      for (final m in _xmlRe.allMatches(text)) {
        final s = m.group(0)!;
        if (s.startsWith('<!--')) {
          span(m.start, m.end, p.syntaxComment);
        } else if (s.startsWith('<') || s.endsWith('>')) {
          span(m.start, m.end, p.syntaxKey);
        } else if (s.startsWith('"') || s.startsWith("'")) {
          span(m.start, m.end, p.syntaxString);
        } else {
          span(m.start, m.end, p.syntaxNumber);
        }
      }
      break;
    case 'js':
      for (final m in _jsRe.allMatches(text)) {
        final s = m.group(0)!;
        if (s.startsWith('//') || s.startsWith('/*')) {
          span(m.start, m.end, p.syntaxComment);
        } else if (s[0] == '"' || s[0] == "'" || s[0] == '`') {
          span(m.start, m.end, p.syntaxString);
        } else if (RegExp(r'[0-9]').hasMatch(s[0])) {
          span(m.start, m.end, p.syntaxNumber);
        } else {
          span(m.start, m.end, p.syntaxKeyword);
        }
      }
      break;
  }
  if (text.contains('{{')) {
    for (final m in varRe.allMatches(text)) {
      final n = m.group(1)!;
      final ok =
          known.contains(n) ||
          n.startsWith(r'$') ||
          n.startsWith('process.env.') ||
          (n.contains('.') && known.contains(n.substring(0, n.indexOf('.'))));
      span(m.start, m.end, ok ? p.ok : p.err, true);
    }
  }
  if (query.isNotEmpty) {
    final lt = text.toLowerCase(), lq = query.toLowerCase();
    var i = lt.indexOf(lq);
    while (i >= 0) {
      r.add(
        StyleRange(
          i,
          i + query.length,
          color: p.text,
          background: p.accent.withValues(alpha: 0.45),
        ),
      );
      i = lt.indexOf(lq, i + query.length);
    }
  }
  return buildStyledSpan(text, style ?? const TextStyle(), r);
}

List<String> codeLines(String text) {
  final out = <String>[];
  for (final l in text.split('\n')) {
    if (l.length <= 3000) {
      out.add(l);
    } else {
      for (var i = 0; i < l.length; i += 3000) {
        out.add(l.substring(i, math.min(l.length, i + 3000)));
      }
    }
  }
  return out;
}

class HighlightTransform extends TextEditingController {
  String lang = 'text';
  Pal? pal;
  Set<String> known = const {};

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (pal == null) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return highlight(text, lang, pal!, known: known, style: style);
  }
}
