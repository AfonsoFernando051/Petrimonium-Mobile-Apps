import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/features/pet/data/models/pet_specie_enum.dart';
import 'package:petrimonium/features/pet/domain/entities/pet_profile.dart';
import 'package:petrimonium/features/pet/domain/enums/accessory_type.dart';
import 'package:petrimonium/features/pet/domain/enums/pet_accessory_id.dart';
import 'package:petrimonium/features/pet/domain/enums/pet_evolution_stage.dart';
import 'package:petrimonium/features/pet/domain/repositories/mascot_repository.dart';
import 'package:petrimonium/features/pet/presentation/companion/pet_companion_controller.dart';
import 'package:petrimonium/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium/features/onboarding/presentation/screens/quick_setup_screen.dart';
import 'package:petrimonium/features/profile/presentation/screens/mentor_preferences_screen.dart';
import 'package:petrimonium/features/profile/presentation/screens/privacy_and_memory_screen.dart';
import 'package:petrimonium/features/profile/presentation/screens/profile_screen.dart';
import 'package:petrimonium/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal in-memory MascotRepository double — mirrors the one in
/// `mascot_controller_test.dart`; these tests only need a working
/// `MascotController`/`PetCompanionController`, not real persistence.
class FakeMascotRepository implements MascotRepository {
  // CAT rather than the default DOG: DOG now ships a real `dog.riv`, and
  // this project's pinned `rive`/`rive_common` versions hit a native-symbol
  // lookup failure once `flutter_tester` actually parses `.riv` bytes on
  // this toolchain (see `pet_rive_companion_test.dart`). CAT has no bundled
  // asset, so the embedded PetCompanionHeader keeps exercising the real,
  // always-reachable fallback path deterministically.
  @override
  Future<PetProfile> loadProfile() async => PetProfile(specie: PetSpecieEnum.CAT);

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
  late PetCompanionController companionController;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});

    // SettingsScreen (pushed from this screen) reads DI.mascotRepository on
    // init — kept a working double so navigating into it doesn't crash.
    DI.mascotRepository = FakeMascotRepository();

    mascotController = MascotController(repository: FakeMascotRepository());
    companionController = PetCompanionController(mascotController: mascotController);
  });

  Widget buildTestable() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: ProfileScreen(companionController: companionController),
    );
  }

  group('ProfileScreen', () {
    testWidgets('renders the identity subtitle and exactly the 3 mockup rows', (tester) async {
      await tester.pumpWidget(buildTestable());
      // CosmicBackground has repeating AnimationControllers — never
      // pumpAndSettle here.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Petrimonium · Academy + Wallet'), findsOneWidget);
      expect(find.text('Preferências do Mentor'), findsOneWidget);
      expect(find.text('Privacidade e memória'), findsOneWidget);
      expect(find.text('Moeda-base e mercado'), findsOneWidget);
      expect(find.text('Configurações do app'), findsNothing);
    });

    testWidgets('back button pops the screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(companionController: companionController),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ProfileScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('tapping the AppBar gear icon navigates to SettingsScreen', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('tapping "Preferências do Mentor" navigates to MentorPreferencesScreen', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Preferências do Mentor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MentorPreferencesScreen), findsOneWidget);
    });

    testWidgets('tapping "Privacidade e memória" navigates to PrivacyAndMemoryScreen', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Privacidade e memória'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PrivacyAndMemoryScreen), findsOneWidget);
    });

    testWidgets('tapping "Moeda-base e mercado" navigates to QuickSetupScreen in settings mode', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Moeda-base e mercado'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final quickSetup = tester.widget<QuickSetupScreen>(find.byType(QuickSetupScreen));
      expect(quickSetup.isSettingsMode, isTrue);
      // Settings mode has no onboarding progress dots and its own "Salvar" CTA.
      expect(find.text('Salvar'), findsOneWidget);
    });
  });
}
