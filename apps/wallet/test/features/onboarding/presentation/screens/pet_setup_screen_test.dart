import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/features/onboarding/presentation/screens/mentor_welcome_screen.dart';
import 'package:petrimonium_wallet/features/onboarding/presentation/screens/pet_setup_screen.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/pet/domain/repositories/pet_repository.dart';

class FakePetRepository implements PetRepository {
  bool hasPet = false;
  bool shouldFail = false;
  final List<PetSpecieEnum> configuredSpecies = [];

  @override
  Future<void> configurePet(PetSpecieEnum specie) async {
    if (shouldFail) throw Exception('boom');
    configuredSpecies.add(specie);
    hasPet = true;
  }

  @override
  Future<bool> getPetStatus() async => hasPet;

  @override
  Future<Map<String, dynamic>?> getMyPet() async => null;
}

class FakeMascotRepository implements MascotRepository {
  final List<String> savedNames = [];

  @override
  Future<PetProfile> loadProfile() async => PetProfile(name: savedNames.isEmpty ? null : savedNames.last);

  @override
  Future<void> saveName(String name) async {
    savedNames.add(name);
  }

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
  late FakePetRepository petRepository;
  late FakeMascotRepository mascotRepository;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    petRepository = FakePetRepository();
    mascotRepository = FakeMascotRepository();
    DI.petRepository = petRepository;
    DI.mascotRepository = mascotRepository;
  });

  Widget buildThemedTestableWidget() {
    return MaterialApp(theme: AppTheme.dark, home: const PetSetupScreen());
  }

  group('PetSetupScreen', () {
    testWidgets('renders title, the locked-species portrait and a disabled CTA until a name is typed', (tester) async {
      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      expect(find.text('Crie seu Pet'), findsOneWidget);
      // Picker escondido enquanto o custo de rigging no Rive prende cada app
      // a uma mascote fixa (Wallet = DOG) — ver _kSpeciesPickerVisible.
      expect(find.text('Escolha uma espécie'), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Criar meu Pet e continuar'), findsOneWidget);

      final button = tester.widget<GameButton>(find.byType(GameButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'typing a name enables the CTA; submitting configures the default species, saves the name and moves on to MentorWelcomeScreen',
      (tester) async {
        await tester.pumpWidget(buildThemedTestableWidget());
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'Toby');
        await tester.pump();

        final enabledButton = tester.widget<GameButton>(find.byType(GameButton));
        expect(enabledButton.onPressed, isNotNull);

        await tester.tap(find.byType(GameButton), warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(petRepository.configuredSpecies, [PetSpecieEnum.DOG]);
        expect(mascotRepository.savedNames, ['Toby']);
        expect(find.byType(MentorWelcomeScreen), findsOneWidget);
      },
    );

    testWidgets('a failed submission shows an error and keeps the user on PetSetupScreen', (tester) async {
      petRepository.shouldFail = true;

      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Toby');
      await tester.pump();

      await tester.tap(find.byType(GameButton), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(mascotRepository.savedNames, isEmpty);
      expect(find.byType(PetSetupScreen), findsOneWidget);
      expect(find.byType(MentorWelcomeScreen), findsNothing);
    });
  });
}
