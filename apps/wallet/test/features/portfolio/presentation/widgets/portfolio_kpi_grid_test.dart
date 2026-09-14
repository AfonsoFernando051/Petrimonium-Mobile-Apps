import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_shared_features/testing.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/core/widgets/layer_chip.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/portfolio_kpi_grid.dart';

import '../controllers/portfolio_controller_test.dart';

DividendEvent paid(double amount, DateTime date) => DividendEvent(
  ticker: 'PETR4',
  type: DividendType.DIVIDENDO,
  rawLabel: 'Dividendo',
  ratePerShare: 1,
  dataCom: date,
  paymentDate: date,
  approvedOn: date,
  userQuantity: 1,
  estimatedGrossAmount: amount,
  status: DividendStatus.PAID,
);

void main() {
  late FakePortfolioRepository repository;
  late PortfolioController controller;

  setUp(() {
    Translator.currentLanguage = 'pt';
    repository = FakePortfolioRepository();
    controller = PortfolioController(
      repository: repository,
      achievementsLocalRepository: FakeAchievementsLocalRepository(),
      achievementsRepository: FakeAchievementsRepository(),
      gamificationRepository: FakeGamificationRepository(),
      missionsRepository: FakeMissionsRepository(),
    );
  });

  tearDown(() => controller.dispose());

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: PortfolioKpiGrid(controller: controller)),
    );
  }

  group('PortfolioKpiGrid', () {
    testWidgets('shows the four headline tiles', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('PATRIMÔNIO TOTAL'), findsOneWidget);
      expect(find.text('LUCRO TOTAL'), findsOneWidget);
      expect(find.text('PROVENTOS (12M)'), findsOneWidget);
      expect(find.text('RENTABILIDADE'), findsOneWidget);
    });

    testWidgets('shows the real patrimônio, invested capital and today delta', (tester) async {
      final holdings = [lot(ticker: 'PETR4', quantity: 100, purchasePrice: 10)];
      repository.holdingsToReturn = Holding.fromLots(holdings);
      repository.summaryToReturn = const PortfolioSummary(
        investedCapital: 44890,
        currentValue: 47320.18,
        totalGain: 1145.28,
        totalGainPercent: 15.7,
        totalAssets: 1,
      );
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('R\$ 47.320,18'), findsOneWidget);
      expect(find.text('Valor investido: R\$ 44.890,00'), findsOneWidget);
      expect(find.text('Total · 15.7%'), findsOneWidget);
    });

    testWidgets('waits for the real dividend radar instead of showing a zero it has not fetched', (tester) async {
      repository.summaryToReturn = const PortfolioSummary(
        investedCapital: 1000,
        currentValue: 1200,
        totalGain: 200,
        totalGainPercent: 20,
        totalAssets: 1,
      );
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Proventos and lucro total both depend on the radar — until it has
      // been fetched they must read as unknown, never as R$ 0,00.
      expect(find.text('--'), findsNWidgets(2));
      expect(find.text('Buscando seus proventos confirmados…'), findsNWidgets(2));
    });

    testWidgets('adds real proventos to the capital gain once the radar has loaded', (tester) async {
      repository.summaryToReturn = const PortfolioSummary(
        investedCapital: 44890,
        currentValue: 47320.18,
        totalGain: 1145.28,
        totalGainPercent: 15.7,
        totalAssets: 1,
      );
      repository.dividendRadarToReturn = DividendRadar(
        upcoming: const [],
        history: [paid(1284.90, DateTime.now().subtract(const Duration(days: 30)))],
      );
      await controller.loadAll();
      await controller.loadDividendRadarIfNeeded();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('R\$ 1.284,90'), findsOneWidget); // proventos tile
      expect(find.text('R\$ 2.430,18'), findsOneWidget); // 1145,28 capital + 1284,90 proventos
      expect(find.text('Capital: R\$ 1.145,28'), findsOneWidget);
      expect(find.text('Proventos: R\$ 1.284,90'), findsOneWidget);
      expect(find.text('--'), findsNothing);
    });

    testWidgets('states the provenance of the whole block once, as data', (tester) async {
      await controller.loadAll();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final chip = tester.widget<LayerChip>(find.byType(LayerChip));
      expect(chip.layer, DataLayer.data);
      expect(chip.label, startsWith('DADO · brapi.dev'));
    });

    testWidgets('says so when some quote is stale rather than implying full freshness', (tester) async {
      repository.holdingsToReturn = Holding.fromLots([
        lot(ticker: 'CDB', type: InvestmentTypeEnum.FIXED_INCOME, priceStatus: PriceStatus.stalePurchasePrice),
      ]);
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.textContaining('algumas cotações indisponíveis'), findsOneWidget);
    });
  });
}
