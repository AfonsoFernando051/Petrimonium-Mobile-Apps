import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/features/investment/data/models/asset_registration_model.dart';
import 'package:petrimonium_wallet/features/investment/data/repositories/investment_repository.dart';
import 'package:petrimonium_wallet/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';

import '../../../portfolio/presentation/controllers/portfolio_controller_test.dart';

class MockInvestmentRepository extends Mock implements InvestmentRepository {}

void main() {
  late FakePortfolioRepository portfolioRepository;
  late MockInvestmentRepository investmentRepository;
  late PortfolioController controller;

  setUpAll(() {
    registerFallbackValue(
      AssetRegistrationModel(
        name: 'FALLBACK',
        quantity: 1,
        purchasePrice: 1,
        purchaseDate: '2024-01-01',
        type: InvestmentTypeEnum.STOCKS,
      ),
    );
  });

  setUp(() {
    portfolioRepository = FakePortfolioRepository();
    investmentRepository = MockInvestmentRepository();
    controller = PortfolioController(
      repository: portfolioRepository,
      achievementsLocalRepository: FakeAchievementsLocalRepository(),
      achievementsRepository: FakeAchievementsRepository(),
      gamificationRepository: FakeGamificationRepository(),
      missionsRepository: FakeMissionsRepository(),
    );

    when(() => investmentRepository.searchQuotes(any())).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => investmentRepository.fetchQuoteAtDate(any(), any())).thenAnswer((_) async => null);
    when(() => investmentRepository.addInvestment(any())).thenAnswer((_) async {});

    DI.portfolioRepository = portfolioRepository;
    DI.investmentRepository = investmentRepository;
  });

  tearDown(() => controller.dispose());

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddAssetScreen(controller: controller))),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('AddAssetScreen', () {
    testWidgets('renders the title, mentor tip, all 6 type options and a disabled CTA', (tester) async {
      await openScreen(tester);

      expect(find.text('Adicionar ativo'), findsWidgets);
      expect(
        find.text(
          'Cada ativo que você registra deixa sua carteira mais completa — eu uso isso para te dar leituras melhores.',
        ),
        findsOneWidget,
      );
      for (final label in ['Ações', 'R. Fixa', 'FIIs', 'Cripto', 'ETFs', 'Outros']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('R\$ 0,00'), findsNWidgets(2));

      final button = tester.widget<GameButton>(find.byType(GameButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'filling type/ticker/quantity/price/date enables the CTA; submitting appends only the new asset and pops back',
      (tester) async {
        await openScreen(tester);

        await tester.tap(find.text('Ações'));
        await tester.pump();

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'PETR4');
        await tester.enterText(textFields.at(1), '10');
        await tester.enterText(textFields.at(2), '25');
        await tester.pump();

        await tester.ensureVisible(find.text('Data de Compra'));
        await tester.tap(find.text('Data de Compra'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('OK'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final button = tester.widget<GameButton>(find.byType(GameButton));
        expect(button.onPressed, isNotNull);

        await tester.tap(find.byType(GameButton), warnIfMissed: false);
        // Several async gaps between the submit call and the pop: addInvestment
        // -> controller.refresh() (a full loadAll()) -> Navigator.pop() —
        // bounded pumps in a loop rather than a fixed count of awaits.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        final captured = verify(() => investmentRepository.addInvestment(captureAny())).captured;
        final submitted = captured.single as AssetRegistrationModel;
        expect(submitted.name, 'PETR4');
        expect(submitted.quantity, 10);
        expect(submitted.purchasePrice, 25);

        // Regression guard: the granular screen must never fall back to the
        // full-replace endpoint.
        verifyNever(
          () => investmentRepository.configureInvestments(any(), confirmReplace: any(named: 'confirmReplace')),
        );

        expect(find.byType(AddAssetScreen), findsNothing);
      },
    );

    testWidgets('an addInvestment failure shows a friendly error and does not pop', (tester) async {
      when(() => investmentRepository.addInvestment(any())).thenThrow(Exception('server exploded'));

      await openScreen(tester);

      await tester.tap(find.text('Ações'));
      await tester.pump();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'PETR4');
      await tester.enterText(textFields.at(1), '10');
      await tester.enterText(textFields.at(2), '25');
      await tester.pump();

      await tester.ensureVisible(find.text('Data de Compra'));
      await tester.tap(find.text('Data de Compra'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(GameButton), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Não foi possível adicionar o ativo'), findsOneWidget);
      expect(find.byType(AddAssetScreen), findsOneWidget);
    });

    testWidgets('a negative quantity keeps the CTA disabled despite parsing as a number', (tester) async {
      await openScreen(tester);

      await tester.tap(find.text('Ações'));
      await tester.pump();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'PETR4');
      await tester.enterText(textFields.at(1), '-10');
      await tester.enterText(textFields.at(2), '25');
      await tester.pump();

      await tester.ensureVisible(find.text('Data de Compra'));
      await tester.tap(find.text('Data de Compra'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // -10 parses fine as a double, but it's not a valid quantity — the CTA
      // must stay disabled rather than let the user submit a negative lot.
      final button = tester.widget<GameButton>(find.byType(GameButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'selecting a ticker after already picking the purchase date fetches the historical price, not the live quote',
      (tester) async {
        when(() => investmentRepository.searchQuotes(any())).thenAnswer(
          (_) async => [
            {'symbol': 'PETR4', 'shortName': 'Petrobras', 'regularMarketPrice': 25.0},
          ],
        );
        when(
          () => investmentRepository.fetchQuoteAtDate('PETR4', any()),
        ).thenAnswer((_) async => {'regularMarketPrice': 18.5});

        await openScreen(tester);

        // Pick the purchase date BEFORE the ticker is known.
        await tester.ensureVisible(find.text('Data de Compra'));
        await tester.tap(find.text('Data de Compra'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('OK'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Now pick the ticker from the autocomplete.
        await tester.enterText(find.byType(TextFormField).at(0), 'PE');
        await tester.pumpAndSettle();
        await tester.tap(find.text('PETR4'));
        await tester.pumpAndSettle();

        verify(() => investmentRepository.fetchQuoteAtDate('PETR4', any())).called(1);

        final priceField = tester.widget<TextFormField>(find.byType(TextFormField).at(2));
        expect(priceField.controller!.text, '18.5');
      },
    );
  });

  group('AddAssetScreen — edit mode', () {
    final lot = InvestmentLot(
      id: 7,
      ticker: 'PETR4',
      type: InvestmentTypeEnum.STOCKS,
      quantity: 10,
      purchasePrice: 25,
      purchaseDate: DateTime(2024, 1, 1),
      currentPrice: 30,
      investedValue: 250,
      currentValue: 300,
    );

    Future<void> openEditScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddAssetScreen(controller: controller, editingLot: lot),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('pre-fills every field from the lot being edited and shows edit copy', (tester) async {
      await openEditScreen(tester);

      expect(find.text('Editar ativo'), findsWidgets);
      expect(find.text('Salvar alterações'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      expect(tester.widget<TextFormField>(textFields.at(0)).controller!.text, 'PETR4');
      expect(tester.widget<TextFormField>(textFields.at(1)).controller!.text, '10');
      expect(tester.widget<TextFormField>(textFields.at(2)).controller!.text, '25');
      expect(find.text('01/01/2024'), findsOneWidget);

      final button = tester.widget<GameButton>(find.byType(GameButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('submitting calls updateInvestment with the lot id, never addInvestment, and pops with true', (
      tester,
    ) async {
      when(() => investmentRepository.updateInvestment(any(), any())).thenAnswer((_) async {});

      await openEditScreen(tester);

      await tester.enterText(find.byType(TextFormField).at(1), '15');
      await tester.pump();

      await tester.ensureVisible(find.byType(GameButton));
      await tester.tap(find.byType(GameButton), warnIfMissed: false);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final captured = verify(() => investmentRepository.updateInvestment(7, captureAny())).captured;
      final submitted = captured.single as AssetRegistrationModel;
      expect(submitted.name, 'PETR4');
      expect(submitted.quantity, 15);

      verifyNever(() => investmentRepository.addInvestment(any()));
      expect(find.byType(AddAssetScreen), findsNothing);
    });
  });
}
