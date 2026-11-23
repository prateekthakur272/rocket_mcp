import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Icons, Material, MaterialApp;
import 'package:rocket_mcp/components/badge_icon_btn.dart';
import 'package:rocket_mcp/theme/theme.dart';

void main() {
  testWidgets('shows its count and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RocketTheme(
            dark: false,
            child: Center(
              child: BadgeIconBtn(
                icon: Icons.warning_amber_rounded,
                count: 3,
                color: const Color(0xFFC2650A),
                onClick: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byType(BadgeIconBtn));
    expect(taps, 1);
  });
}
