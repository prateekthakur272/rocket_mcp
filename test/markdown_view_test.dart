import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/components/markdown_view.dart';
import 'package:rocket_mcp/features/workspace/resource_runner_view.dart';

void main() {
  group('Markdown parser & view', () {
    test('parses markdown headings, paragraphs, lists, and code fences', () {
      const src = '''
# Title
A paragraph with **bold** and *italic* text.

```json
{"key": "value"}
```

- item 1
- item 2
''';
      final blocks = parseMarkdownBlocks(src);
      expect(blocks.length, 4);
      expect(blocks[0], isA<MdHeading>());
      expect((blocks[0] as MdHeading).text, 'Title');
      expect((blocks[0] as MdHeading).level, 1);

      expect(blocks[1], isA<MdParagraph>());

      expect(blocks[2], isA<MdCode>());
      expect((blocks[2] as MdCode).lang, 'json');
      expect((blocks[2] as MdCode).code, '{"key": "value"}');

      expect(blocks[3], isA<MdList>());
      expect((blocks[3] as MdList).items.length, 2);
    });

    test('parses inline spans with bold, italic, code, and links', () {
      final spans = parseMarkdownInline(
        'Here is `code`, **bold**, and [link](https://example.com)',
      );
      expect(spans.any((s) => s.code && s.text == 'code'), isTrue);
      expect(spans.any((s) => s.bold && s.text == 'bold'), isTrue);
      expect(spans.any((s) => s.link == 'https://example.com'), isTrue);
    });
  });

  group('ResourceRenderMode', () {
    test('converts from labels accurately', () {
      expect(ResourceRenderMode.fromLabel('Raw'), ResourceRenderMode.raw);
      expect(ResourceRenderMode.fromLabel('JSON'), ResourceRenderMode.json);
      expect(ResourceRenderMode.fromLabel('.md'), ResourceRenderMode.markdown);
      expect(
        ResourceRenderMode.fromLabel('Markdown'),
        ResourceRenderMode.markdown,
      );
      expect(ResourceRenderMode.raw.label, 'Raw');
      expect(ResourceRenderMode.json.label, 'JSON');
      expect(ResourceRenderMode.markdown.label, '.md');
    });

    test('detectResourceMode detects .md, JSON, and Raw accurately', () {
      expect(
        detectResourceMode('file:///doc.md', null, null),
        ResourceRenderMode.markdown,
      );
      expect(
        detectResourceMode('file:///notes.txt', 'text/markdown', null),
        ResourceRenderMode.markdown,
      );
      expect(
        detectResourceMode('file:///doc.txt', null, '# Heading\ncontent'),
        ResourceRenderMode.markdown,
      );

      expect(
        detectResourceMode('file:///config.json', null, null),
        ResourceRenderMode.json,
      );
      expect(
        detectResourceMode('file:///data', 'application/json', null),
        ResourceRenderMode.json,
      );
      expect(
        detectResourceMode('file:///unknown', null, '{"status": "ok"}'),
        ResourceRenderMode.json,
      );

      expect(
        detectResourceMode('file:///plain.log', 'text/plain', 'plain text log'),
        ResourceRenderMode.raw,
      );
    });

    test('isMarkdownResource and isJsonResource check applicable formats', () {
      expect(isMarkdownResource('file:///readme.md', null, null), isTrue);
      expect(isJsonResource('file:///readme.md', null, null), isFalse);

      expect(isJsonResource('file:///config.json', null, null), isTrue);
      expect(isMarkdownResource('file:///config.json', null, null), isFalse);

      expect(
        isMarkdownResource('file:///test.txt', 'text/plain', 'hello world'),
        isFalse,
      );
      expect(
        isJsonResource('file:///test.txt', 'text/plain', 'hello world'),
        isFalse,
      );
    });
  });
}
