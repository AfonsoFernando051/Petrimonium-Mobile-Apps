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
///
/// O picker de espécie está escondido (ver `_kSpeciesPickerVisible` no
/// widget) enquanto o custo de rigging no Rive mantém cada app preso a uma
/// mascote fixa — Health = fox. Estes testes cobrem o retrato estático + nome,
/// não a grelha interativa.
void main() {
  Future<void> pumpPetSetup(WidgetTester tester) async {
    final controller = HealthController(repository: _StubRepository(), localeController: LocaleController());
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

  testWidgets('shows the locked species portrait and a name field, no picker', (tester) async {
    await pumpPetSetup(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(PetSetupScreen)));

    // Uma única imagem: o retrato estático da espécie fixa, não a grelha.
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.text(l10n.petSetupSpeciesLabel), findsNothing);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(l10n.petSetupNameLabel), findsOneWidget);
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

    // Título e rótulo do nome à esquerda, na mesma margem (a espécie está
    // escondida enquanto o picker fica desligado).
    final nameLabel = find.text(l10n.petSetupNameLabel);
    expect(tester.getTopLeft(title).dx, tester.getTopLeft(nameLabel).dx);

    // A nota de rodapé é uma caixa com fundo e contorno, não texto solto.
    final noteBox = find.ancestor(of: find.text(l10n.petSetupFooterNote), matching: find.byType(Container));
    final decoration = tester.widget<Container>(noteBox.first).decoration as BoxDecoration;
    expect(decoration.color, HealthColors.inputFill);
    expect(decoration.border, isNotNull);
  });

  testWidgets('gates the CTA on the pet name, not on a species choice', (tester) async {
    await pumpPetSetup(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(PetSetupScreen)));

    HealthPrimaryButton cta() => tester.widget<HealthPrimaryButton>(find.byType(HealthPrimaryButton));
    expect(cta().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Rex');
    await tester.pump();

    expect(cta().onPressed, isNotNull);
    expect(l10n.petSetupNameLabel, isNotEmpty);
  });

  testWidgets('caps the content width on a desktop-sized window', (tester) async {
    // Numa janela larga a coluna esticava a 1920px — o passo do pet ocupava
    // o ecrã inteiro.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPetSetup(tester);

    final nameField = tester.getSize(find.byType(TextField));
    expect(nameField.width, lessThanOrEqualTo(HealthContent.bodyWidth));

    final cta = tester.getSize(find.byType(HealthPrimaryButton));
    expect(cta.width, lessThanOrEqualTo(HealthContent.bodyWidth));

    // O retrato estático continua presente, único.
    expect(find.byType(Image), findsOneWidget);
  });
}

class _StubRepository implements HealthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
