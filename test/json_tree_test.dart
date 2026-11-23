import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;
import 'package:rocket_mcp/components/json_tree.dart';
import 'package:rocket_mcp/theme/theme.dart';

Widget _host(Widget child) => MaterialApp(
  home: Material(child: RocketTheme(dark: false, child: child)),
);

void main() {
  testWidgets(
    'JsonTree renders nested objects and does not overflow on hover in narrow view',
    (tester) async {
      final data = {
        'content': [
          {
            'text': 'Error: Operation failed due to timeout',
            'annotations': {
              'audience': ['user', 'assistant'],
              'priority': 1,
            },
          },
        ],
      };

      // Test with a narrow width where the path might overflow without ellipsis
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            height: 400,
            child: JsonTree(
              root: data,
              expandSignal: 1, // expand all
              onCopy: (_, _) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final priorityFinder = find.text('priority');
      expect(priorityFinder, findsOneWidget);

      // Hover over the priority row
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(priorityFinder));
      await tester.pumpAndSettle();

      // Verify hover widgets appeared
      expect(find.text(r'$.content[0].annotations.priority'), findsOneWidget);

      // Verify no overflow exception was thrown during layout or painting
      expect(tester.takeException(), isNull);
    },
  );
}
