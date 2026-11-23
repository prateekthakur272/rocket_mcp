import 'dart:convert';

/// Checks that [text] is a JSON object, which is what a tool call takes as its arguments.
///
/// Returns null when it is, otherwise a one-line problem for the user, with the line and column of a syntax error
/// (`Unexpected character at line 3, column 5`).
String? argumentsJsonProblem(String text) {
  if (text.trim().isEmpty) return 'Enter a JSON object, such as { }';
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (e) {
    final at = e.offset;
    final reason = e.message
        .split('\n')
        .first
        .replaceAll(RegExp(r'\s*\(at .*\)$'), '');
    if (at == null) return reason;
    final before = text.substring(0, at.clamp(0, text.length));
    final line = '\n'.allMatches(before).length + 1;
    final column = at - (before.lastIndexOf('\n') + 1) + 1;
    return '$reason at line $line, column $column';
  }
  if (decoded is! Map) {
    return 'Arguments must be a JSON object, such as { "name": "value" }';
  }
  return null;
}
