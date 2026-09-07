import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_health/core/app/health_scope.dart';
import 'package:petrimonium_health/core/i18n/locale_controller.dart';
import 'package:petrimonium_health/core/theme/health_theme.dart';
import 'package:petrimonium_health/core/widgets/health_widgets.dart';
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
  testWidgets('lays the step out as the canvas does', (tester) async {
    await pumpPetSetup(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(PetSetupScreen)));

    // Indicador de passo no topo, acima do título — estava junto ao CTA.
    final dots = find.byType(ProgressDots);
    final title = find.text(l10n.petSetupTitle);
    expect(dots, findsOneWidget);
    expect(tester.getTopLeft(dots).dy, lessThan(tester.getTopLeft(title).dy));

    // Título e subtítulo à esquerda, na mesma margem dos rótulos.
    final speciesLabel = find.text(l10n.petSetupSpeciesLabel);
    expect(tester.getTopLeft(title).dx, tester.getTopLeft(speciesLabel).dx);

    // A nota de rodapé é uma caixa com fundo e contorno, não texto solto.
    final noteBox = find.ancestor(
      of: find.text(l10n.petSetupFooterNote),
      matching: find.byType(Container),
    );
    final decoration = tester.widget<Container>(noteBox.first).decoration as BoxDecoration;
    expect(decoration.color, HealthColors.inputFill);
    expect(decoration.border, isNotNull);
  });

  testWidgets('selection changes the label weight, never its colour', (tester) async {
    await pumpPetSetup(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(PetSetupScreen)));

    Text labelOf(PetSpecies s) => tester.widget<Text>(find.text(_label(tester, s)));

    // fox é o pré-selecionado no artboard `PetHealth`.
    expect(labelOf(PetSpecies.fox).style?.fontWeight, FontWeight.w700);
    expect(labelOf(PetSpecies.lion).style?.fontWeight, FontWeight.w400);
    // No canvas as sete espécies partilham a cor do rótulo.
    expect(labelOf(PetSpecies.fox).style?.color, labelOf(PetSpecies.lion).style?.color);
    expect(labelOf(PetSpecies.fox).style?.color, HealthColors.textSecondary);
    expect(l10n.petSetupSpeciesLabel, isNotEmpty);
  });

  testWidgets('caps the content width on a desktop-sized window', (tester) async {
    // Numa janela larga a coluna esticava a 1920px e a grelha dava cartões de
    // ~480px — o passo do pet ocupava o ecrã inteiro com quatro espécies.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPetSetup(tester);

    // Medir o contentor, não a largura intrínseca do texto: esta última é a
    // mesma com ou sem limite, e deixava o teste passar à mesma.
    final grid = tester.getSize(find.byType(GridView));
    expect(grid.width, lessThanOrEqualTo(HealthContent.bodyWidth));

    final cta = tester.getSize(find.byType(HealthPrimaryButton));
    expect(cta.width, lessThanOrEqualTo(HealthContent.bodyWidth));

    // As sete espécies continuam presentes, em duas linhas de quatro.
    expect(find.byType(Image), findsNWidgets(PetSpecies.values.length));
    final firstOfRow = tester.getTopLeft(find.text(_label(tester, PetSpecies.fox)));
    final lastOfRow = tester.getTopLeft(find.text(_label(tester, PetSpecies.owl)));
    expect(lastOfRow.dx - firstOfRow.dx, lessThan(HealthContent.bodyWidth));
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
