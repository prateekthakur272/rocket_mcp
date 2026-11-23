import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;
import 'package:rocket_mcp/features/workspace/traffic_packet_view.dart';
import 'package:rocket_mcp/theme/theme.dart';

void main() {
  testWidgets('asks for a message to be selected when there is none', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RocketTheme(
            dark: false,
            child: TrafficPacketView(
              entry: null,
              onToggleLayout: () {},
              isVertical: true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Select a message'), findsOneWidget);
  });
}
