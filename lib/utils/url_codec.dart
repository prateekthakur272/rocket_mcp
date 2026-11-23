import 'dart:convert';

/// encodeURIComponent / decodeURIComponent equivalents that leave `{{variables}}` alone.
class UrlCodec {
  UrlCodec._();

  static final RegExp _varRe = RegExp(r'\{\{[^{}]*\}\}');
  static final RegExp _pctRe = RegExp(r'%[0-9A-Fa-f]{2}');

  static bool looksEncoded(String s) => _pctRe.hasMatch(s);

  static String decode(String s) {
    // '+' stays '+' (decodeURIComponent semantics); only %XX sequences are decoded
    try {
      final src = s.replaceAll('+', '%2B');
      final bytes = <int>[];
      final sb = StringBuffer();
      void flush() {
        if (bytes.isNotEmpty) {
          sb.write(utf8.decode(bytes, allowMalformed: true));
          bytes.clear();
        }
      }

      var i = 0;
      while (i < src.length) {
        final c = src[i];
        if (c == '%') {
          if (i + 3 > src.length) {
            return s; // incomplete escape
          }
          final h = int.tryParse(src.substring(i + 1, i + 3), radix: 16);
          if (h == null) return s;
          bytes.add(h);
          i += 3;
        } else {
          flush();
          sb.write(c);
          i++;
        }
      }
      flush();
      return sb.toString();
    } catch (_) {
      return s;
    }
  }

  static String encode(String s) {
    final sb = StringBuffer();
    var last = 0;
    for (final m in _varRe.allMatches(s)) {
      sb.write(_encodePart(s.substring(last, m.start)));
      sb.write(m.group(0));
      last = m.end;
    }
    sb.write(_encodePart(s.substring(last)));
    return sb.toString();
  }

  /// Form-style encoding: unreserved = [A-Za-z0-9.-*_]; space -> '+'.
  static String _encodePart(String s) {
    final sb = StringBuffer();
    for (final b in utf8.encode(s)) {
      final c = b;
      final unreserved =
          (c >= 0x30 && c <= 0x39) ||
          (c >= 0x41 && c <= 0x5A) ||
          (c >= 0x61 && c <= 0x7A) ||
          c == 0x2E ||
          c == 0x2D ||
          c == 0x2A ||
          c == 0x5F;
      if (unreserved) {
        sb.writeCharCode(c);
      } else if (c == 0x20) {
        sb.write('%20');
      } else {
        sb.write('%${c.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return sb.toString().replaceAll('*', '%2A').replaceAll('%7E', '~');
  }
}
