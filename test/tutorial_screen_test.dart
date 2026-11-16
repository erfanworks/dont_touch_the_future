import 'package:dont_touch_the_future/features/tutorial/presentation/tutorial_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('walks through 3 steps and ends with START PLAYING',
      (tester) async {
    final app = await buildTestApp(const TutorialScreen());
    await tester.pumpWidget(app.widget);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('DRAG TO MOVE'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('YOUR PAST RETURNS IN 3 SECONDS'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text("DON'T TOUCH YOUR ECHO"), findsOneWidget);
    expect(find.text('START PLAYING'), findsOneWidget);
  });
}
