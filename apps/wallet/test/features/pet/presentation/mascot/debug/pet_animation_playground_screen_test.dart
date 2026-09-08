import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/debug/pet_animation_playground_screen.dart';

void main() {
  Widget buildTestableWidget() => const MaterialApp(home: PetAnimationPlaygroundScreen());

  testWidgets('renders and loads a profile without throwing', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(PetAnimationPlaygroundScreen), findsOneWidget);
  });

  testWidgets('every state button drives the mascot without throwing', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();
    await tester.pump();

    for (final label in const [
      'idle',
      'celebrate',
      'think',
      'sleep',
      'victory',
      'happy',
      'talking',
      'listening',
      'sad',
    ]) {
      await tester.tap(find.widgetWithText(ElevatedButton, label));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('size slider and toggles update without throwing', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();
    await tester.pump();

    await tester.drag(find.byType(Slider), const Offset(-80, 0));
    await tester.pump();

    final attentiveSwitch = find.widgetWithText(SwitchListTile, 'attentive (interaction sheet open)');
    await tester.ensureVisible(attentiveSwitch);
    await tester.tap(attentiveSwitch);
    await tester.pump();

    final reducedMotionSwitch = find.widgetWithText(
      SwitchListTile,
      'reducedMotion (MediaQuery.disableAnimations)',
    );
    await tester.ensureVisible(reducedMotionSwitch);
    await tester.tap(reducedMotionSwitch);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
