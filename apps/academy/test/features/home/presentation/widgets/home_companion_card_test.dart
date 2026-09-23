import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/events/app_event.dart';
import 'package:petrimonium_academy/core/events/app_event_bus.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/rive/pet_rive_companion.dart';
import 'package:petrimonium_academy/features/home/presentation/widgets/home_companion_card.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';

/// Minimal in-memory MascotRepository double, mirrors
/// `choice_question_step_view_test.dart` — CAT rather than the default DOG,
/// since DOG's real `dog.riv` crashes `flutter_tester` on this toolchain.
class FakeMascotRepository implements MascotRepository {
  PetProfile profileToReturn = PetProfile(specie: PetSpecieEnum.CAT);

  @override
  Future<PetProfile> loadProfile() async => profileToReturn;
  @override
  Future<void> saveName(String name) async {}
  @override
  Future<void> saveStage(PetEvolutionStage stage) async {}
  @override
  Future<void> saveXp(int xp) async {}
  @override
  Future<void> saveSpecie(PetSpecieEnum specie) async {}
  @override
  Future<void> saveNetWorth(double netWorth) async {}
  @override
  Future<void> saveEquippedAccessories(Map<AccessoryType, PetAccessoryId> equipped) async {}
  @override
  Future<void> saveUnlockedAccessories(Set<PetAccessoryId> unlocked) async {}
  @override
  Future<void> saveLastActiveAt(DateTime lastActiveAt) async {}
}

void main() {
  late MascotController mascotController;

  setUp(() async {
    Translator.currentLanguage = 'pt';
    mascotController = MascotController(repository: FakeMascotRepository());
    await mascotController.loadProfile();
  });

  tearDown(() => mascotController.dispose());

  Widget buildTestable({required HomeCompanionReason reason}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        // Keyed by reason so each loop iteration below mounts a fresh
        // State — otherwise Flutter reuses the previous element/State at
        // the same tree position and `_showReason` leaks across iterations.
        body: HomeCompanionCard(
          key: ValueKey(reason),
          mascotController: mascotController,
          petName: 'Bolt',
          message: 'Sua próxima aula é "Aula X". Vamos aprender?',
          reason: reason,
        ),
      ),
    );
  }

  group('HomeCompanionCard', () {
    testWidgets('renders the pet name and message', (tester) async {
      await tester.pumpWidget(buildTestable(reason: HomeCompanionReason.continueLesson));
      // Hosts a live pet render (repeating AnimationController) — never
      // call pumpAndSettle.
      await tester.pump();

      expect(find.text('Bolt'), findsOneWidget);
      expect(find.text('Sua próxima aula é "Aula X". Vamos aprender?'), findsOneWidget);
      expect(find.text('Por que estou vendo isto?'), findsOneWidget);
    });

    testWidgets('reveals the matching reason for each signal on tap', (tester) async {
      for (final (reason, expected) in [
        (HomeCompanionReason.continueLesson, 'Baseado na próxima aula disponível na sua trilha.'),
        (HomeCompanionReason.reviewDue, 'Baseado em conceitos pendentes de revisão.'),
        (HomeCompanionReason.returning, 'Baseado no tempo desde sua última visita.'),
      ]) {
        await tester.pumpWidget(buildTestable(reason: reason));
        await tester.pump();

        expect(find.text(expected), findsNothing);
        await tester.tap(find.text('Por que estou vendo isto?'));
        await tester.pump();
        expect(find.text(expected), findsOneWidget);
      }
    });

    testWidgets('shows the level and XP progress from the real profile', (tester) async {
      await tester.pumpWidget(buildTestable(reason: HomeCompanionReason.continueLesson));
      await tester.pump();

      expect(find.text('Nível 1'), findsOneWidget);
      expect(find.textContaining('XP para o próximo nível'), findsOneWidget);
    });

    testWidgets('petting the character at rest plays the short happy reaction, then reverts', (tester) async {
      // Fixed midday `now` so the resting state is idle, not night-time sleep.
      await mascotController.loadProfile(now: DateTime(2026, 1, 1, 12));

      await tester.pumpWidget(buildTestable(reason: HomeCompanionReason.continueLesson));
      await tester.pump();

      final pet = find.ancestor(of: find.byType(PetRiveCompanion), matching: find.byType(GestureDetector)).first;
      await tester.tap(pet, warnIfMissed: false);
      await tester.pump();
      expect(mascotController.animationState, PetAnimationState.happy);

      await tester.pump(const Duration(seconds: 1));
      expect(mascotController.animationState, isNot(PetAnimationState.happy));
    });

    testWidgets('celebrates a real level-up from AppEventBus without throwing', (tester) async {
      await tester.pumpWidget(buildTestable(reason: HomeCompanionReason.continueLesson));
      await tester.pump();

      AppEventBus.instance.emit(const UserLeveledUpEvent(5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('honors disableAnimations', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: buildTestable(reason: HomeCompanionReason.reviewDue),
        ),
      );
      await tester.pump();

      AppEventBus.instance.emit(const UserLeveledUpEvent(5));
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      expect(find.text('Bolt'), findsOneWidget);
    });
  });
}
