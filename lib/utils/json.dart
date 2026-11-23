/// Minimal dependency-free JSON parser / writer. Objects -> LinkedHashMap, arrays -> List, numbers -> int/double.
library;

class JsonException implements Exception {
  final String message;
  JsonException(this.message);
  @override
  String toString() => message;
}

/// Whether a character counts as whitespace.
bool isKtWhitespace(int c) =>
    (c >= 9 && c <= 13) ||
    (c >= 28 && c <= 32) ||
    c == 0xA0 ||
    c == 0x1680 ||
    (c >= 0x2000 && c <= 0x200A) ||
    c == 0x2028 ||
    c == 0x2029 ||
    c == 0x202F ||
    c == 0x205F ||
    c == 0x3000;

/// Formats a double as the shortest round-trip decimal, with an exponent for large or tiny values.
String javaDouble(double d) {
  if (d.isNaN) return 'NaN';
  if (d.isInfinite) return d < 0 ? '-Infinity' : 'Infinity';
  if (d == 0) return (1 / d).isNegative ? '-0.0' : '0.0';
  final neg = d < 0;
  final a = d.abs();
  // shortest round-trip digits and decimal exponent from Dart's toString
  String digits;
  int exp; // value = 0.d1d2d3... * 10^exp
  final s = a.toString();
  if (s.contains('e')) {
    final parts = s.split('e');
    final mant = parts[0].replaceAll('.', '');
    final mantDot = parts[0].indexOf('.');
    final intLen = mantDot < 0 ? parts[0].length : mantDot;
    digits = mant;
    exp = int.parse(parts[1]) + intLen - 1;
  } else {
    final dot = s.indexOf('.');
    final ip = dot < 0 ? s : s.substring(0, dot);
    final fp = dot < 0 ? '' : s.substring(dot + 1);
    final all = ip + fp;
    var lead = 0;
    while (lead < all.length - 1 && all[lead] == '0') {
      lead++;
    }
    digits = all.substring(lead);
    exp = ip.length - 1 - lead;
  }
  digits = digits.replaceFirst(RegExp(r'0+$'), '');
  if (digits.isEmpty) digits = '0';
  String out;
  if (a >= 1e-3 && a < 1e7) {
    if (exp >= 0) {
      final ip = digits.length > exp + 1
          ? digits.substring(0, exp + 1)
          : digits.padRight(exp + 1, '0');
      final fp = digits.length > exp + 1 ? digits.substring(exp + 1) : '0';
      out = '$ip.$fp';
    } else {
      out = '0.${'0' * (-exp - 1)}$digits';
    }
  } else {
    final fp = digits.length > 1 ? digits.substring(1) : '0';
    out = '${digits[0]}.${fp}E$exp';
  }
  return neg ? '-$out' : out;
}

/// JSON parse and write helpers.
class Json {
  Json._();

  static dynamic parse(String s) => _Parser(s).top();

  static dynamic tryParse(String s) {
    try {
      return parse(s);
    } catch (_) {
      return null;
    }
  }

  static bool isValid(String s) {
    try {
      parse(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic>? obj(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, x) => MapEntry(k.toString(), x));
    return null;
  }

  static List<dynamic>? arr(dynamic v) => v is List ? v : null;

  static String? str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is double) {
      if (v % 1.0 == 0.0 && v.abs() < 1e15) return v.toInt().toString();
      return javaDouble(v);
    }
    return v.toString();
  }

  static String stringify(
    dynamic v, {
    bool pretty = false,
    String indent = '  ',
  }) {
    final sb = StringBuffer();
    _write(sb, v, pretty, indent, 0);
    return sb.toString();
  }

  static String quote(String s) {
    final sb = StringBuffer('"');
    for (final c in s.codeUnits) {
      switch (c) {
        case 0x22:
          sb.write('\\"');
        case 0x5C:
          sb.write('\\\\');
        case 0x0A:
          sb.write('\\n');
        case 0x0D:
          sb.write('\\r');
        case 0x09:
          sb.write('\\t');
        case 0x08:
          sb.write('\\b');
        case 0x0C:
          sb.write('\\f');
        default:
          if (c < 0x20) {
            sb.write('\\u${c.toRadixString(16).padLeft(4, '0')}');
          } else {
            sb.writeCharCode(c);
          }
      }
    }
    sb.write('"');
    return sb.toString();
  }

  static void _write(
    StringBuffer sb,
    dynamic v,
    bool pretty,
    String ind,
    int depth,
  ) {
    if (v == null) {
      sb.write('null');
    } else if (v is String) {
      sb.write(quote(v));
    } else if (v is bool || v is int) {
      sb.write(v.toString());
    } else if (v is double) {
      sb.write(str(v));
    } else if (v is num) {
      sb.write(v.toString());
    } else if (v is Map) {
      if (v.isEmpty) {
        sb.write('{}');
        return;
      }
      sb.write('{');
      var first = true;
      for (final e in v.entries) {
        if (!first) sb.write(',');
        first = false;
        if (pretty) {
          sb.write('\n');
          sb.write(ind * (depth + 1));
        }
        sb.write(quote(e.key.toString()));
        sb.write(pretty ? ': ' : ':');
        _write(sb, e.value, pretty, ind, depth + 1);
      }
      if (pretty) {
        sb.write('\n');
        sb.write(ind * depth);
      }
      sb.write('}');
    } else if (v is List) {
      if (v.isEmpty) {
        sb.write('[]');
        return;
      }
      sb.write('[');
      var first = true;
      for (final x in v) {
        if (!first) sb.write(',');
        first = false;
        if (pretty) {
          sb.write('\n');
          sb.write(ind * (depth + 1));
        }
        _write(sb, x, pretty, ind, depth + 1);
      }
      if (pretty) {
        sb.write('\n');
        sb.write(ind * depth);
      }
      sb.write(']');
    } else {
      sb.write(quote(v.toString()));
    }
  }

  /// Re-indent JSON text without altering string/number literals. Returns null if the text is not valid JSON.
  static String? prettyText(String text, {String indent = '  '}) {
    if (!isValid(text)) return null;
    final sb = StringBuffer();
    var depth = 0;
    var i = 0;
    final n = text.length;
    void nl() {
      sb.write('\n');
      sb.write(indent * depth);
    }

    while (i < n) {
      final c = text[i];
      if (c == '"') {
        final st = i;
        i++;
        while (i < n && text[i] != '"') {
          if (text[i] == '\\') i++;
          i++;
        }
        sb.write(text.substring(st, (i + 1) < n ? i + 1 : n));
      } else if (c == '{' || c == '[') {
        var j = i + 1;
        while (j < n && isKtWhitespace(text.codeUnitAt(j))) {
          j++;
        }
        final close = c == '{' ? '}' : ']';
        if (j < n && text[j] == close) {
          sb.write(c);
          sb.write(close);
          i = j;
        } else {
          sb.write(c);
          depth++;
          nl();
        }
      } else if (c == '}' || c == ']') {
        depth--;
        nl();
        sb.write(c);
      } else if (c == ',') {
        sb.write(c);
        nl();
      } else if (c == ':') {
        sb.write(': ');
      } else if (isKtWhitespace(c.codeUnitAt(0))) {
      } else {
        sb.write(c);
      }
      i++;
    }
    return sb.toString();
  }
}

class _Parser {
  final String s;
  int i = 0;
  _Parser(this.s);

  Never err([String m = 'Unexpected token']) =>
      throw JsonException('$m at position $i');
  bool _isDigit(int c) => c >= 0x30 && c <= 0x39;
  void ws() {
    while (i < s.length && isKtWhitespace(s.codeUnitAt(i))) {
      i++;
    }
  }

  dynamic top() {
    ws();
    final v = value();
    ws();
    if (i < s.length) err();
    return v;
  }

  dynamic value() {
    ws();
    if (i >= s.length) err('Unexpected end');
    final c = s[i];
    switch (c) {
      case '{':
        return obj();
      case '[':
        return arr();
      case '"':
        return string();
      case 't':
        return lit('true', true);
      case 'f':
        return lit('false', false);
      case 'n':
        return lit('null', null);
      default:
        if (c == '-' || _isDigit(c.codeUnitAt(0))) return number();
        err();
    }
  }

  dynamic lit(String w, dynamic v) {
    if (!s.startsWith(w, i)) err();
    i += w.length;
    return v;
  }

  dynamic number() {
    final st = i;
    if (s[i] == '-') i++;
    while (i < s.length &&
        (_isDigit(s.codeUnitAt(i)) || '.eE+-'.contains(s[i]))) {
      i++;
    }
    final t = s.substring(st, i);
    return int.tryParse(t) ?? double.tryParse(t) ?? err('Bad number');
  }

  String string() {
    i++;
    final sb = StringBuffer();
    while (true) {
      if (i >= s.length) err('Unterminated string');
      final c = s[i++];
      if (c == '"') return sb.toString();
      if (c == '\\') {
        if (i >= s.length) err();
        final e = s[i++];
        switch (e) {
          case 'n':
            sb.write('\n');
          case 't':
            sb.write('\t');
          case 'r':
            sb.write('\r');
          case 'b':
            sb.write('\b');
          case 'f':
            sb.write('\u000C');
          case 'u':
            sb.writeCharCode(int.parse(s.substring(i, i + 4), radix: 16));
            i += 4;
          default:
            sb.write(e);
        }
      } else {
        sb.write(c);
      }
    }
  }

  Map<String, dynamic> obj() {
    i++;
    final m = <String, dynamic>{};
    ws();
    if (i < s.length && s[i] == '}') {
      i++;
      return m;
    }
    while (true) {
      ws();
      if (i >= s.length || s[i] != '"') err('Expected key');
      final k = string();
      ws();
      if (i >= s.length || s[i] != ':') err("Expected ':'");
      i++;
      m[k] = value();
      ws();
      if (i >= s.length) err('Unexpected end');
      if (s[i] == ',') {
        i++;
        continue;
      }
      if (s[i] == '}') {
        i++;
        return m;
      }
      err();
    }
  }

  List<dynamic> arr() {
    i++;
    final l = <dynamic>[];
    ws();
    if (i < s.length && s[i] == ']') {
      i++;
      return l;
    }
    while (true) {
      l.add(value());
      ws();
      if (i >= s.length) err('Unexpected end');
      if (s[i] == ',') {
        i++;
        continue;
      }
      if (s[i] == ']') {
        i++;
        return l;
      }
      err();
    }
  }
}

/// Tiny path query used by response filter and post-response vars: `$.a.b[0].c`, `a.b`, `[0].x`.
class JsonPath {
  JsonPath._();

  static final RegExp _re = RegExp(
    r'''\.?([^.\[\]]+)|\[(\d+|"[^"]*"|'[^']*')\]''',
  );

  static String _trimQuotes(String s) {
    var a = 0;
    var b = s.length;
    while (a < b && (s[a] == '"' || s[a] == "'")) {
      a++;
    }
    while (b > a && (s[b - 1] == '"' || s[b - 1] == "'")) {
      b--;
    }
    return s.substring(a, b);
  }

  static dynamic query(dynamic root, String path) {
    var p = path.trim();
    if (p.startsWith(r'$')) p = p.substring(1);
    dynamic cur = root;
    for (final m in _re.allMatches(p)) {
      final g1 = m.group(1) ?? '';
      final key = _trimQuotes(g1.isNotEmpty ? g1 : (m.group(2) ?? ''));
      if (cur is Map) {
        cur = cur[key];
      } else if (cur is List) {
        if (key == 'length') {
          cur = cur.length;
        } else {
          final idx = int.tryParse(key);
          cur = (idx != null && idx >= 0 && idx < cur.length) ? cur[idx] : null;
        }
      } else {
        return null;
      }
    }
    return cur;
  }
}
