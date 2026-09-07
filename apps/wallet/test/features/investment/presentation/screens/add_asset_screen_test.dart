import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/widgets/game_button.dart';
import 'package:petrimonium/features/investment/data/models/asset_registration_model.dart';
import 'package:petrimonium/features/investment/data/repositories/investment_repository.dart';
import 'package:petrimonium/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium/features/portfolio/domain/entities/holding.dart';
import 'package:petrimonium/features/portfolio/presentation/controllers/portfolio_controller.dart';

import '../../../portfolio/presentation/controllers/portfolio_controller_test.dart';
import '../../../portfolio/domain/services/portfolio_test_fixtures.dart';

class MockInvestmentRepository extends Mock implements InvestmentRepository {}

void main() {
  late FakePortfolioRepository portfolioRepository;
  late MockInvestmentRepository investmentRepository;
  late PortfolioController controller;

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
    when(() => investmentRepository.configureInvestments(any(), confirmReplace: any(named: 'confirmReplace')))
        .thenAnswer((_) async {});

    // AddAssetScreen reads `DI.portfolioRepository` directly to seed existing
    // holdings, independently of the `PortfolioController`'s own repository
    // — the same fake is assigned to both so they agree on what "existing"
    // means.
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddAssetScreen(controller: controller)),
            ),
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
      'filling type/ticker/quantity/price/date enables the CTA; submitting resubmits existing holdings plus the new asset and pops back',
      (tester) async {
        final existingLot = lot(ticker: 'VALE3', quantity: 10, purchasePrice: 60);
        portfolioRepository.holdingsToReturn = Holding.fromLots([existingLot]);

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
        // Several async gaps between the submit call and the pop: configure
        // -> controller.refresh() (a full loadAll()) -> Navigator.pop() —
        // bounded pumps in a loop rather than a fixed count of awaits.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        final captured = verify(
          () => investmentRepository.configureInvestments(captureAny(), confirmReplace: true),
        ).captured;
        final submitted = captured.single as List<AssetRegistrationModel>;
        expect(submitted.map((a) => a.name), containsAll(['VALE3', 'PETR4']));
        expect(submitted.length, 2);

        expect(find.byType(AddAssetScreen), findsNothing);
      },
    );

    testWidgets('a configureInvestments failure shows a friendly error and does not pop', (tester) async {
      when(() => investmentRepository.configureInvestments(any(), confirmReplace: any(named: 'confirmReplace')))
          .thenThrow(Exception('server exploded'));

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
  });
}
