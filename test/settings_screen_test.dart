import 'package:dont_touch_the_future/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('shows the three switches and the about section', (tester) async {
    final app = await buildTestApp(const SettingsScreen());
    await tester.pumpWidget(app.widget);
    await tester.pump();

    expect(find.byType(Switch), findsNWidgets(3));
    expect(find.text('SOUND EFFECTS'), findsOneWidget);
    expect(find.text('HAPTIC FEEDBACK'), findsOneWidget);
    expect(find.text('REDUCED MOTION'), findsOneWidget);
    expect(find.text('PRIVACY POLICY'), findsOneWidget);
    expect(find.text('ABOUT GAME'), findsOneWidget);
  });

  testWidgets('reduced motion toggle updates and persists', (tester) async {
    final app = await buildTestApp(const SettingsScreen());
    await tester.pumpWidget(app.widget);
    await tester.pump();

    expect(app.settings.reducedMotion, isFalse);
    await tester.tap(find.byType(Switch).at(2));
    await tester.pump();

    expect(app.settings.reducedMotion, isTrue);
    expect(app.storage.reducedMotion, isTrue);
  });

  testWidgets('privacy policy opens a placeholder dialog', (tester) async {
    final app = await buildTestApp(const SettingsScreen());
    await tester.pumpWidget(app.widget);
    await tester.pump();

    await tester.tap(find.text('PRIVACY POLICY'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Privacy Policy'), findsOneWidget);
  });
}
