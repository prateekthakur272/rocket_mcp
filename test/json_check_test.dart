import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/utils/json_check.dart';

void main() {
  group('argumentsJsonProblem', () {
    test('accepts an object, including an empty one', () {
      expect(argumentsJsonProblem('{}'), isNull);
      expect(argumentsJsonProblem('{\n  "a": 1,\n  "b": [true]\n}'), isNull);
    });

    test('rejects empty text', () {
      expect(argumentsJsonProblem('  '), isNotNull);
    });

    test('rejects JSON that is not an object', () {
      expect(argumentsJsonProblem('[1, 2]'), contains('JSON object'));
      expect(argumentsJsonProblem('"text"'), contains('JSON object'));
    });

    test('reports the line and column of a syntax error', () {
      final problem = argumentsJsonProblem('{\n  "a": 1,\n  "b": }');
      expect(problem, contains('line 3'));
      expect(problem, contains('column'));
    });
  });
}
