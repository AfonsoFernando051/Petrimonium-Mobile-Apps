import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_health/core/app/health_scope.dart';
import 'package:petrimonium_health/core/i18n/locale_controller.dart';
import 'package:petrimonium_health/features/health/data/health_repository.dart';
import 'package:petrimonium_health/features/health/domain/pet_species.dart';
import 'package:petrimonium_health/features/health/presentation/health_controller.dart';
import 'package:petrimonium_health/features/onboarding/presentation/pet_setup_screen.dart';
import 'package:petrimonium_health/l10n/app_localizations.dart';

/// O catálogo de espécies é partilhado com a Wallet e a Academy — a conta é a
/// mesma nos três apps. Um catálogo mais curto aqui deixaria um Pet criado
/// noutro app sem representação nesta.
void main() {
  Future<void> pumpPetSetup(WidgetTester tester) async {
    final controller = HealthController(
      repository: _StubRepository(),
      localeController: LocaleController(),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HealthScope(controller: controller, child: const PetSetupScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('offers all seven species, in the design canvas order', (tester) async {
    await pumpPetSetup(tester);

    // Ordem do artboard `PetHealth`.
    const expected = [
      PetSpecies.fox,
      PetSpecies.dog,
      PetSpecies.cat,
      PetSpecies.owl,
      PetSpecies.wolf,
      PetSpecies.bear,
      PetSpecies.lion,
    ];
    expect(PetSpecies.values, expected);

    for (final species in expected) {
      expect(find.text(_label(tester, species)), findsOneWidget, reason: species.name);
    }
    expect(find.byType(Image), findsNWidgets(expected.length));
  });

  test('every species resolves to art that actually exists on disk', () {
    // Verificação em disco, e não via `Image.asset`/`rootBundle`: em
    // `flutter test` nenhum dos dois falha quando o ficheiro não existe — o
    // widget resolve tarde e engole o erro, e o bundle devolve dados de
    // esquema. Era a ausência alegada desta arte que mantinha wolf, bear e
    // lion fora do catálogo.
    for (final species in PetSpecies.values) {
      expect(species.assetPath, 'assets/pets/${species.name}.png');
      expect(File(species.assetPath).existsSync(), isTrue, reason: species.assetPath);
    }
  });

  test('a species created in another app maps back to this catalog', () {
    for (final species in PetSpecies.values) {
      expect(PetSpecies.fromApiValue(species.apiValue), species, reason: species.apiValue);
    }
    // O backend envia o wire format em maiúsculas; nenhum dos sete pode voltar nulo.
    expect(PetSpecies.fromApiValue('WOLF'), PetSpecies.wolf);
    expect(PetSpecies.fromApiValue('LION'), PetSpecies.lion);
    expect(PetSpecies.fromApiValue('BEAR'), PetSpecies.bear);
  });
}

String _label(WidgetTester tester, PetSpecies species) {
  final l10n = AppLocalizations.of(tester.element(find.byType(PetSetupScreen)));
  return switch (species) {
    PetSpecies.fox => l10n.speciesFox,
    PetSpecies.dog => l10n.speciesDog,
    PetSpecies.cat => l10n.speciesCat,
    PetSpecies.owl => l10n.speciesOwl,
    PetSpecies.wolf => l10n.speciesWolf,
    PetSpecies.bear => l10n.speciesBear,
    PetSpecies.lion => l10n.speciesLion,
  };
}

class _StubRepository implements HealthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
