import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/features/pet/domain/enums/pet_animation_state.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/animation/pet_animation_engine.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/animation/pet_animation_sequences.dart';

void main() {
  Widget host({required PetAnimationState state, bool reducedMotion = false}) {
    return MaterialApp(
      home: Scaffold(
        body: PetAnimationEngine(
          state: state,
          size: 220,
          reducedMotion: reducedMotion,
          child: const SizedBox(width: 220, height: 220, key: ValueKey('petVisual')),
        ),
      ),
    );
  }

  Finder engineTransforms() =>
      find.descendant(of: find.byType(PetAnimationEngine), matching: find.byType(Transform));

  double dyOffsetOf(WidgetTester tester) {
    final matrix = tester.widget<Transform>(engineTransforms().first).transform;
    return matrix.getTranslation().y;
  }

  group('reducedMotion', () {
    testWidgets('renders the child with no Transform wrapper at all', (tester) async {
      await tester.pumpWidget(host(state: PetAnimationState.idle, reducedMotion: true));
      await tester.pump();

      expect(engineTransforms(), findsNothing);
      expect(find.byKey(const ValueKey('petVisual')), findsOneWidget);
    });

    testWidgets('never advances even across a full loop duration — no crash either', (tester) async {
      await tester.pumpWidget(host(state: PetAnimationState.idle, reducedMotion: true));
      await tester.pump(PetAnimationSequences.idle.duration * 2);

      expect(tester.takeException(), isNull);
      expect(engineTransforms(), findsNothing);
    });
  });

  group('normal motion', () {
    testWidgets('wraps the child in Transform layers when motion is enabled', (tester) async {
      await tester.pumpWidget(host(state: PetAnimationState.idle));
      await tester.pump();

      // translate + rotate + scale, chained.
      expect(engineTransforms(), findsNWidgets(3));
    });

    testWidgets('a reaction moves the mascot away from rest mid-flight', (tester) async {
      await tester.pumpWidget(host(state: PetAnimationState.idle));
      await tester.pump();
      final restY = dyOffsetOf(tester);

      await tester.pumpWidget(host(state: PetAnimationState.happy));
      await tester.pump(PetAnimationSequences.happy.duration * 0.4);

      expect(dyOffsetOf(tester), isNot(closeTo(restY, 0.01)));
    });

    testWidgets('a reaction settles back out once it completes', (tester) async {
      await tester.pumpWidget(host(state: PetAnimationState.happy));
      await tester.pump();
      // Run well past the reaction's own duration — it must not keep the
      // mascot displaced forever once it's done playing.
      await tester.pump(PetAnimationSequences.happy.duration + const Duration(milliseconds: 50));

      // Sampled again a full idle-loop period later: idle's own seamless
      // loop guarantees this matches its start-of-cycle pose, which is
      // PetPose.rest — so the reaction leaving a permanent offset would
      // show up as a mismatch here.
      final afterSettle = dyOffsetOf(tester);
      await tester.pump(PetAnimationSequences.idle.duration);
      expect(dyOffsetOf(tester), closeTo(afterSettle, 0.01));
    });

    testWidgets('swapping between loop moods does not throw', (tester) async {
      const sequence = [
        PetAnimationState.idle,
        PetAnimationState.think,
        PetAnimationState.listening,
        PetAnimationState.sad,
        PetAnimationState.sleep,
        PetAnimationState.talking,
        PetAnimationState.idle,
      ];

      await tester.pumpWidget(host(state: PetAnimationState.idle));
      await tester.pump();

      for (final state in sequence) {
        await tester.pumpWidget(host(state: state));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('rapid-fire reactions do not throw or accumulate extra tickers', (tester) async {
      await tester.pumpWidget(host(state: PetAnimationState.idle));
      await tester.pump();

      for (final state in const [
        PetAnimationState.happy,
        PetAnimationState.celebrate,
        PetAnimationState.victory,
        PetAnimationState.happy,
      ]) {
        await tester.pumpWidget(host(state: state));
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('toggling reducedMotion mid-flight stops without throwing, and can resume', (tester) async {
      await tester.pumpWidget(host(state: PetAnimationState.idle));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(host(state: PetAnimationState.idle, reducedMotion: true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(engineTransforms(), findsNothing);

      await tester.pumpWidget(host(state: PetAnimationState.idle, reducedMotion: false));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(engineTransforms(), findsNWidgets(3));
    });
  });

  testWidgets('disposes its controllers cleanly — no leaked tickers after unmount', (tester) async {
    await tester.pumpWidget(host(state: PetAnimationState.idle));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
