import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/components/header_bar.dart';

const _first = ValueKey('first');
const _title = ValueKey('title');
const _trailing = ValueKey('trailing');

Widget _bar(double width) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: width,
      height: 38,
      child: const HeaderBar(
        leading: [
          SizedBox(key: _first, width: 200, height: 14),
          SizedBox(key: _title, width: 300, height: 20),
        ],
        trailing: [SizedBox(key: _trailing, width: 300, height: 20)],
      ),
    ),
  ),
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('keeps leading at the start and trailing at the end when wide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_bar(900));
    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(find.byKey(_first)).dx, 0);
    expect(tester.getTopRight(find.byKey(_trailing)).dx, 900);
  });

  testWidgets(
    'shrinks the leading items first, keeping the trailing controls',
    (tester) async {
      await tester.pumpWidget(_bar(450));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(_trailing)).width, 300);
      expect(tester.getSize(find.byKey(_title)).width, lessThan(300));
    },
  );

  testWidgets('scales the trailing controls down when they alone do not fit', (
    tester,
  ) async {
    await tester.pumpWidget(_bar(200));
    expect(tester.takeException(), isNull);
    // The child keeps its own size but is drawn scaled; its box is what must fit the bar.
    expect(
      tester.getSize(find.byType(FittedBox)).width,
      lessThanOrEqualTo(200),
    );
  });
}
