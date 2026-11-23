import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/utils/uri_template.dart';

void main() {
  group('URI Template extraction', () {
    test('extracts single simple variable', () {
      expect(
        extractTemplateVariables('demo://resource/dynamic/blob/{resourceId}'),
        ['resourceId'],
      );
    });

    test('extracts reserved variables and paths', () {
      expect(extractTemplateVariables('file:///{+path}'), ['path']);
    });

    test('extracts multiple variables across path segments', () {
      expect(
        extractTemplateVariables('repos/{owner}/{repo}/issues/{issueId}'),
        ['owner', 'repo', 'issueId'],
      );
    });

    test('extracts multiple query variables in single expression', () {
      expect(extractTemplateVariables('search://items{?query,limit,offset}'), [
        'query',
        'limit',
        'offset',
      ]);
    });

    test('strips modifiers like explode and prefix length', () {
      expect(extractTemplateVariables('api://data/{list*}/{prefix:3}'), [
        'list',
        'prefix',
      ]);
    });

    test('detects presence of template variables', () {
      expect(
        hasTemplateVariables('demo://resource/dynamic/blob/{resourceId}'),
        isTrue,
      );
      expect(hasTemplateVariables('file:///docs/readme.md'), isFalse);
    });
  });

  group('URI Template resolution', () {
    test('resolves single simple variable', () {
      final res = resolveUriTemplate(
        'demo://resource/dynamic/blob/{resourceId}',
        {'resourceId': '123'},
      );
      expect(res, 'demo://resource/dynamic/blob/123');
      expect(hasUnresolvedVariables(res), isFalse);
    });

    test('leaves unfilled variables in place', () {
      final res = resolveUriTemplate(
        'demo://resource/dynamic/blob/{resourceId}',
        {},
      );
      expect(res, 'demo://resource/dynamic/blob/{resourceId}');
      expect(hasUnresolvedVariables(res), isTrue);
    });

    test('resolves reserved path expansion without escaping slashes', () {
      final res = resolveUriTemplate('file:///{+path}', {
        'path': 'docs/architecture.md',
      });
      expect(res, 'file:///docs/architecture.md');
      expect(hasUnresolvedVariables(res), isFalse);
    });

    test('resolves query parameters', () {
      final res = resolveUriTemplate('search://items{?query,limit}', {
        'query': 'mcp testing',
        'limit': '10',
      });
      expect(res, 'search://items?query=mcp%20testing&limit=10');
      expect(hasUnresolvedVariables(res), isFalse);
    });

    test('omits missing query parameters cleanly', () {
      final res = resolveUriTemplate('search://items{?query,limit}', {
        'query': 'mcp testing',
      });
      expect(res, 'search://items?query=mcp%20testing');
    });

    test('distinguishes query vs path variables', () {
      const tmpl = 'items://{id}/details{?format,debug}';
      expect(isQueryTemplateVariable(tmpl, 'id'), isFalse);
      expect(isQueryTemplateVariable(tmpl, 'format'), isTrue);
      expect(isQueryTemplateVariable(tmpl, 'debug'), isTrue);
    });

    test('reports unresolved variables', () {
      const uri = 'items://{id}/details?format=json';
      expect(hasUnresolvedVariables(uri), isTrue);
      expect(getUnresolvedVariables(uri), ['id']);
    });
  });
}
