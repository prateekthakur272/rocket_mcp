import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;
import 'package:rocket_mcp/components/toggle.dart';
import 'package:rocket_mcp/features/workspace/tool_argument_field.dart';
import 'package:rocket_mcp/theme/theme.dart';

Widget _host(Widget child) => MaterialApp(
  home: Material(child: RocketTheme(dark: false, child: child)),
);

void main() {
  testWidgets('a boolean argument is a switch that reports changes', (
    tester,
  ) async {
    Object? changed;
    await tester.pumpWidget(
      _host(
        ToolArgumentField(
          name: 'verbose',
          schema: const {'type': 'boolean'},
          isRequired: false,
          value: false,
          onChange: (v) => changed = v,
        ),
      ),
    );
    await tester.tap(find.byType(Toggle));
    expect(changed, true);
  });

  testWidgets('an enum argument shows its current choice and "enum" badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ToolArgumentField(
          name: 'mode',
          schema: const {
            'type': 'string',
            'enum': ['fast', 'slow'],
          },
          isRequired: true,
          value: 'fast',
          onChange: (_) {},
        ),
      ),
    );
    expect(find.text('fast'), findsOneWidget);
    expect(find.text('enum'), findsOneWidget);
    expect(find.text('*'), findsOneWidget);
  });

  testWidgets('a numeric argument is stored as a number', (tester) async {
    Object? changed;
    await tester.pumpWidget(
      _host(
        ToolArgumentField(
          name: 'count',
          schema: const {'type': 'integer'},
          isRequired: false,
          value: null,
          onChange: (v) => changed = v,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '42');
    expect(changed, 42);
  });
}
