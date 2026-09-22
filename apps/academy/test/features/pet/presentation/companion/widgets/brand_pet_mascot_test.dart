import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/rive/pet_rive_companion.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/widgets/brand_pet_mascot.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// `.riv` loading is off for the whole run (see `test/flutter_test_config.dart`),
/// so what renders here is always the portrait fallback. What these tests are
/// really pinning is the configuration [BrandPetMascot] hands to
/// [PetRiveCompanion] — the part that decides *which* character a brand screen
/// is allowed to show.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );

  PetRiveCompanion companionOf(WidgetTester tester) => tester.widget<PetRiveCompanion>(find.byType(PetRiveCompanion));

  testWidgets('defaults to the brand mascot (wolf), never the player profile', (tester) async {
    await tester.pumpWidget(host(const BrandPetMascot(size: 96)));
    await tester.pump();

    final companion = companionOf(tester);
    expect(companion.specieOverride, PetSpecieEnum.WOLF);
    // Without the override the widget would sit waiting for a profile these
    // screens must not load — there is no signed-in player yet.
    expect(companion.controller.hasLoadedProfile, isFalse);
  });

  testWidgets('renders the species it is given, for the onboarding step that names the pet', (tester) async {
    await tester.pumpWidget(host(const BrandPetMascot(size: 96, specie: PetSpecieEnum.FOX)));
    await tester.pump();

    expect(companionOf(tester).specieOverride, PetSpecieEnum.FOX);
  });

  testWidgets('never downgrades a brand screen to a stopgap rig', (tester) async {
    await tester.pumpWidget(host(const BrandPetMascot(size: 96, specie: PetSpecieEnum.DOG)));
    await tester.pump();

    // dog.riv/owl.riv are differently-drawn reference assets; a brand screen
    // keeps its original portrait rather than swapping to them.
    expect(companionOf(tester).allowStopgapRigs, isFalse);
    expect(companionOf(tester).fallbackBuilder, isNotNull);
  });

  testWidgets('shows the species portrait while no rig renders', (tester) async {
    await tester.pumpWidget(host(const BrandPetMascot(size: 96)));
    await tester.pump();
    await tester.pump();

    expect(find.descendant(of: find.byType(PetRiveCompanion), matching: find.byType(Image)), findsOneWidget);
  });

  testWidgets('with no size, fills the box its parent allows', (tester) async {
    await tester.pumpWidget(host(const SizedBox(width: 140, height: 80, child: BrandPetMascot())));
    await tester.pump();

    // The square side is the smaller constraint, so the character is never
    // clipped by the parent (PetHeroCapsule relies on this).
    expect(companionOf(tester).size, 80);
  });
}
