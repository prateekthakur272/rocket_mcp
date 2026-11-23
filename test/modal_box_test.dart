import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/theme/theme.dart';

void main() {
  testWidgets(
    'a dialog taller than the window scrolls instead of overflowing',
    (tester) async {
      tester.view.physicalSize = const Size(900, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: RocketTheme(
              dark: false,
              child: ModalBox(
                title: 'Tall',
                onClose: () {},
                actions: const [SizedBox(width: 50, height: 30)],
                content: const [SizedBox(width: 100, height: 1200)],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final box = tester.getSize(find.byType(ModalBox));
      expect(box.height, lessThanOrEqualTo(500));
    },
  );
}
