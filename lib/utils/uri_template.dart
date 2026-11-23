/// Utility functions for parsing and expanding RFC 6570 URI Templates.
library;

/// Extracts all variable names enclosed in `{...}` in a URI template.
///
/// Handles simple variables `{var}`, operator prefixes like `{+path}`, `{?query,limit}`,
/// and variable modifiers like `{list*}` and `{prefix:3}`.
List<String> extractTemplateVariables(String uriTemplate) {
  final reg = RegExp(r'\{([+#./;?&]?)([^}]+)\}');
  final vars = <String>[];
  for (final match in reg.allMatches(uriTemplate)) {
    final rawList = match.group(2) ?? '';
    for (final v in rawList.split(',')) {
      final name = v.trim().replaceAll(RegExp(r'[*:]\d*$'), '');
      if (name.isNotEmpty && !vars.contains(name)) {
        vars.add(name);
      }
    }
  }
  return vars;
}

/// Checks whether a variable is part of a query expansion (e.g. `{?var}` or `{&var}`).
bool isQueryTemplateVariable(String template, String varName) {
  final reg = RegExp(r'\{([?&])([^}]+)\}');
  for (final match in reg.allMatches(template)) {
    final list = match.group(2) ?? '';
    for (final v in list.split(',')) {
      if (v.trim().replaceAll(RegExp(r'[*:]\d*$'), '') == varName) {
        return true;
      }
    }
  }
  return false;
}

/// Checks whether a URI string contains template variable expressions like `{var}`.
bool hasTemplateVariables(String uri) {
  return RegExp(r'\{([+#./;?&]?)([^}]+)\}').hasMatch(uri);
}

/// Checks whether a URI string still contains unresolved `{var}` placeholders.
bool hasUnresolvedVariables(String uri) {
  return hasTemplateVariables(uri);
}

/// Returns the list of unresolved variable names remaining in the URI.
List<String> getUnresolvedVariables(String uri) {
  return extractTemplateVariables(uri);
}

/// Resolves an RFC 6570 URI template by substituting values from [values].
///
/// Unfilled simple variables remain as `{name}` so users can see which parameters
/// are still pending.
String resolveUriTemplate(String template, Map<String, String> values) {
  final reg = RegExp(r'\{([+#./;?&]?)([^}]+)\}');
  return template.replaceAllMapped(reg, (match) {
    final op = match.group(1) ?? '';
    final rawList = match.group(2) ?? '';
    final varNames = rawList
        .split(',')
        .map((v) => v.trim().replaceAll(RegExp(r'[*:]\d*$'), ''))
        .where((n) => n.isNotEmpty)
        .toList();

    if (op == '?') {
      // Query expansion: {?foo,bar} -> ?foo=1&bar=2
      final queryParts = <String>[];
      for (final name in varNames) {
        final val = values[name];
        if (val != null && val.isNotEmpty) {
          queryParts.add('$name=${Uri.encodeComponent(val)}');
        }
      }
      return queryParts.isEmpty ? '' : '?${queryParts.join('&')}';
    } else if (op == '&') {
      // Query continuation
      final queryParts = <String>[];
      for (final name in varNames) {
        final val = values[name];
        if (val != null && val.isNotEmpty) {
          queryParts.add('$name=${Uri.encodeComponent(val)}');
        }
      }
      return queryParts.isEmpty ? '' : '&${queryParts.join('&')}';
    } else if (op == '+') {
      // Reserved expansion: does not escape reserved URI characters (e.g. slashes)
      final parts = varNames
          .map((name) {
            final val = values[name];
            if (val == null || val.isEmpty) return '{+$name}';
            return val;
          })
          .join(',');
      return parts;
    } else {
      // Simple variable expansion
      final parts = varNames
          .map((name) {
            final val = values[name];
            if (val == null || val.isEmpty) return '{$name}';
            return Uri.encodeComponent(val);
          })
          .join(',');
      return parts;
    }
  });
}
