import 'package:flutter/material.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/widgets/pet_hero_capsule.dart';
import 'package:petrimonium_academy/features/pet/presentation/widgets/pet_preview_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_academy/core/di/dependency_injection.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/academy_intro_screen.dart';
import 'package:petrimonium_academy/features/pet/data/models/pet_specie_enum.dart';
import 'package:petrimonium_academy/features/pet/domain/repositories/mascot_repository.dart';
import 'package:petrimonium_academy/features/pet/domain/repositories/pet_repository.dart';
import 'package:petrimonium_academy/features/pet/presentation/widgets/pet_species_selector.dart';
import 'package:petrimonium_academy/features/onboarding/presentation/screens/pet_configuration_screen.dart';

class MockPetRepository extends Mock implements PetRepository {}

class MockMascotRepository extends Mock implements MascotRepository {}

void main() {
  late MockPetRepository mockPetRepository;
  late MockMascotRepository mockMascotRepository;

  setUpAll(() {
    registerFallbackValue(PetSpecieEnum.DOG);
  });

  setUp(() {
    Translator.currentLanguage = 'pt';
    mockPetRepository = MockPetRepository();
    DI.petRepository = mockPetRepository;
    mockMascotRepository = MockMascotRepository();
    DI.mascotRepository = mockMascotRepository;
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: const PetConfigurationScreen(),
    );
  }

  group('PetConfigurationScreen', () {
    testWidgets('renders the title, subtitle, locked-species portrait and name field', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      // Hosts CosmicBackground and a pulsing GameButton — both repeating
      // AnimationControllers, so never call pumpAndSettle.
      await tester.pump();

      expect(find.text('Escolha seu parceiro de jornada'), findsOneWidget);
      expect(
        find.text('Ele evolui com o que você aprende — nunca com quanto você tem.'),
        findsOneWidget,
      );
      expect(find.text('Mas antes... eu preciso de um nome!'), findsOneWidget);
      expect(find.text('Como você gostaria de chamar seu companheiro?'), findsOneWidget);
      // Picker escondido enquanto o custo de rigging no Rive prende cada app
      // a uma mascote fixa (Academy = WOLF) — ver _kSpeciesPickerVisible.
      expect(find.byType(PetSpeciesSelector), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows a required-name error when continuing without typing a name', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text('Vamos começar!'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Escolha um nome para continuar'), findsOneWidget);
      verifyNever(() => mockPetRepository.configurePet(any(), name: any(named: 'name')));
    });

    testWidgets('picking a name suggestion clears the error and fills the field', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text('Vamos começar!'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('Escolha um nome para continuar'), findsOneWidget);

      final boltChip = find.text('Bolt');
      await tester.ensureVisible(boltChip);
      await tester.pump();
      await tester.tap(boltChip, warnIfMissed: false);
      await tester.pump();

      expect(find.text('Escolha um nome para continuar'), findsNothing);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Bolt');
    });

    testWidgets('continuing with a valid name configures the pet and navigates to AcademyIntroScreen', (tester) async {
      when(() => mockPetRepository.configurePet(any(), name: any(named: 'name'))).thenAnswer((_) async {});
      when(() => mockMascotRepository.saveName(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Loki');
      await tester.pump();

      await tester.tap(find.text('Vamos começar!'), warnIfMissed: false);
      await tester.pump(); // loading state
      await tester.pump(); // configurePet + saveName resolve
      await tester.pump(const Duration(milliseconds: 350)); // route transition

      // Lobo é o default da Academy — o mascote do app, pré-selecionado no artboard.
      verify(() => mockPetRepository.configurePet(PetSpecieEnum.WOLF, name: 'Loki')).called(1);
      verify(() => mockMascotRepository.saveName('Loki')).called(1);
      expect(find.byType(AcademyIntroScreen), findsOneWidget);
    });

    testWidgets('shows a friendly error snackbar when configurePet fails', (tester) async {
      when(() => mockPetRepository.configurePet(any(), name: any(named: 'name'))).thenThrow(Exception('boom'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Max');
      await tester.pump();

      await tester.tap(find.text('Vamos começar!'), warnIfMissed: false);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Falha ao salvar o pet'), findsOneWidget);
    });
    testWidgets('lays the step out as the canvas does: one flat column, portrait then name', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // O artboard `PetAcademy` não tem o painel lateral nem a cápsula
      // circular do mascote — leva do retrato estático direto para o nome
      // (a grelha de espécies está escondida, ver _kSpeciesPickerVisible).
      expect(find.byType(PetPreviewPanel), findsNothing);
      expect(find.byType(PetHeroCapsule), findsNothing);

      final portrait = find.byType(Image);
      final nameLabel = find.text('Mas antes... eu preciso de um nome!');
      expect(portrait, findsOneWidget);
      expect(nameLabel, findsOneWidget);
      expect(
        tester.getTopLeft(nameLabel).dy,
        greaterThan(tester.getTopLeft(portrait).dy),
        reason: 'o nome vem depois do retrato, como no canvas',
      );
    });

  });
}
