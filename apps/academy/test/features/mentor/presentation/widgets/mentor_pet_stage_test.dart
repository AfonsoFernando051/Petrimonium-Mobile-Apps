import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/features/mentor/presentation/controllers/mentor_chat_controller.dart';
import 'package:petrimonium_academy/features/mentor/presentation/widgets/mentor_pet_stage.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/rive/pet_rive_companion.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

class FakeMascotRepository implements MascotRepository {
  @override
  Future<PetProfile> loadProfile() async => PetProfile(specie: PetSpecieEnum.WOLF);
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
  const petAsset = 'assets/images/generated_wolf.png';

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );

  PetRiveCompanion companionOf(WidgetTester tester) => tester.widget<PetRiveCompanion>(find.byType(PetRiveCompanion));

  group('MentorPetStage', () {
    late MascotController controller;

    setUp(() => controller = MascotController(repository: FakeMascotRepository()));
    tearDown(() => controller.dispose());

    testWidgets('without a controller it keeps the static portrait', (tester) async {
      await tester.pumpWidget(host(const MentorPetStage(petAsset: petAsset, phase: MentorStagePhase.welcome)));
      await tester.pump();

      expect(find.byType(PetRiveCompanion), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('thinking tilts the character into `think`, screen-locally', (tester) async {
      await controller.loadProfile(now: DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(
        host(MentorPetStage(petAsset: petAsset, phase: MentorStagePhase.thinking, mascotController: controller)),
      );
      await tester.pump();

      expect(companionOf(tester).stateOverride, PetAnimationState.think);
      // The override must not be written back to the controller: the Home hero
      // and the companion header share it and would start thinking too.
      expect(controller.animationState, isNot(PetAnimationState.think));
    });

    testWidgets('welcome and talking leave the character at rest', (tester) async {
      await controller.loadProfile(now: DateTime(2026, 1, 1, 12));

      for (final phase in [MentorStagePhase.welcome, MentorStagePhase.talking]) {
        await tester.pumpWidget(host(MentorPetStage(petAsset: petAsset, phase: phase, mascotController: controller)));
        await tester.pump();

        // No rig has a talking pose — the stage's ring and bob carry it.
        expect(companionOf(tester).stateOverride, PetAnimationState.idle, reason: '$phase');
      }
    });

    testWidgets('only real Companion-contract characters may replace the portrait', (tester) async {
      await controller.loadProfile(now: DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(
        host(MentorPetStage(petAsset: petAsset, phase: MentorStagePhase.welcome, mascotController: controller)),
      );
      await tester.pump();

      expect(companionOf(tester).allowStopgapRigs, isFalse);
      expect(companionOf(tester).fallbackBuilder, isNotNull);
    });
  });
}
