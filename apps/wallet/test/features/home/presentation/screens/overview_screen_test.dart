import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/home/presentation/screens/overview_screen.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/mentor_insight_card.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/allocation_donut_card.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/portfolio_kpi_grid.dart';

import '../../../portfolio/presentation/controllers/portfolio_controller_test.dart';
import 'package:petrimonium_shared_features/testing.dart';

/// Minimal in-memory MascotRepository double — mirrors the one in
/// `profile_screen_test.dart`/`mascot_controller_test.dart`; this screen
/// only needs a working `MascotController` for its `HomePetHero`, not real
/// persistence.
class FakeMascotRepository implements MascotRepository {
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
  late FakePortfolioRepository repository;
  late PortfolioController controller;
  late MascotController mascotController;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    repository = FakePortfolioRepository();
    controller = PortfolioController(repository: repository);
    mascotController = MascotController(repository: FakeMascotRepository());
  });

  tearDown(() {
    controller.dispose();
    mascotController.dispose();
  });

  Widget buildTestableWidget({ValueChanged<int?>? onOpenMentor, VoidCallback? onOpenCarteira}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: OverviewScreen(
          controller: controller,
          onOpenMentor: onOpenMentor ?? (_) {},
          onOpenCarteira: onOpenCarteira ?? () {},
          mascotController: mascotController,
        ),
      ),
    );
  }

  group('OverviewScreen', () {
    testWidgets('shows PortfolioNotConnectedCard when there are no holdings', (tester) async {
      await controller.loadAll();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(PortfolioNotConnectedCard), findsOneWidget);
      expect(find.byType(AllocationDonutCard), findsNothing);
      // Mentor stays locked behind a first asset — see
      // `DashboardScreen._visibleTabIndices`.
      expect(find.byType(MentorInsightCard), findsNothing);
    });

    testWidgets('shows the KPI grid, real change breakdown and a link into the Carteira tab when holdings exist', (
      tester,
    ) async {
      // Purchased well before the 30-day window, no price movement — the
      // real breakdown is all zeros, not the old "coming soon" placeholder.
      final holdings = [lot(ticker: 'PETR4', quantity: 100, purchasePrice: 10)];
      repository.holdingsToReturn = Holding.fromLots(holdings);
      repository.summaryToReturn = statsFromLots(holdings).summary;
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(find.byType(PortfolioNotConnectedCard), findsNothing);
      expect(find.byType(MentorInsightCard), findsOneWidget);
      expect(find.byType(PortfolioKpiGrid), findsOneWidget);
      expect(find.text('PATRIMÔNIO TOTAL'), findsOneWidget);
      expect(find.text('O que mudou (últimos 30 dias)'), findsOneWidget);
      expect(find.text('Valorização'), findsOneWidget);
      expect(find.text('Aportes'), findsOneWidget);
      expect(find.text('Rendimentos'), findsOneWidget);
      expect(find.text('+R\$ 0,00'), findsNWidgets(3));
      // The full wealth-evolution chart and holdings list now live on the
      // dedicated Carteira tab (`CarteiraScreen`), not here — Início only
      // keeps the compact allocation preview + a link into that tab.
      expect(find.byType(AllocationDonutCard), findsOneWidget);
      expect(find.text('Ver carteira completa'), findsOneWidget);
    });

    testWidgets('tapping "Ver carteira completa" invokes onOpenCarteira', (tester) async {
      final holdings = [lot(ticker: 'PETR4', quantity: 100, purchasePrice: 10)];
      repository.holdingsToReturn = Holding.fromLots(holdings);
      repository.summaryToReturn = statsFromLots(holdings).summary;
      await controller.loadAll();

      var opened = false;
      await tester.pumpWidget(buildTestableWidget(onOpenCarteira: () => opened = true));
      await tester.pump();
      await tester.pump();

      await tester.ensureVisible(find.text('Ver carteira completa'));
      await tester.pump();
      await tester.tap(find.text('Ver carteira completa'));
      await tester.pump();

      expect(opened, isTrue);
    });

    testWidgets('the populated dashboard lays out without overflowing a 390x844 phone', (tester) async {
      // The width the reference design is drawn at. Worth an explicit test:
      // the chart legends and the 2x2 KPI tiles are the parts most likely to
      // overflow, and a fixed legend Row really did overflow here by 56px
      // before it was allowed to wrap. Widget tests render in Ahem, whose
      // glyphs are square and therefore *wider* than Outfit's at the same
      // size — so this is a conservative check, not a flattering one.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final now = DateTime.now();
      repository.holdingsToReturn = Holding.fromLots([
        lot(ticker: 'PETR4', quantity: 320, purchasePrice: 28.4),
        lot(ticker: 'HGLG11', type: InvestmentTypeEnum.REAL_ESTATE, quantity: 45, purchasePrice: 155),
      ]);
      repository.summaryToReturn = const PortfolioSummary(
        investedCapital: 44890,
        currentValue: 47320.18,
        totalGain: 1145.28,
        totalGainPercent: 15.7,
        totalAssets: 2,
      );
      repository.allocationToReturn = const [
        AllocationSlice(type: InvestmentTypeEnum.FIXED_INCOME, currentValue: 27420.5, portfolioPercent: 58),
        AllocationSlice(type: InvestmentTypeEnum.STOCKS, currentValue: 12770, portfolioPercent: 27),
        AllocationSlice(type: InvestmentTypeEnum.REAL_ESTATE, currentValue: 7129.68, portfolioPercent: 15),
      ];
      repository.historyByRange = {
        HistoryRange.y1: [
          for (var i = 11; i >= 0; i--)
            HistoryPoint(
              date: DateTime(now.year, now.month - i, 15),
              investedCapital: 30000.0 + (11 - i) * 1300,
              portfolioValue: 31000.0 + (11 - i) * 1450,
            ),
        ],
      };
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.text('R\$ 47.320,18'), findsOneWidget);
      expect(find.text('58%'), findsOneWidget);
    });

    testWidgets('shows the "Bem-vindo(a) de volta" greeting', (tester) async {
      await controller.loadAll();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Bem-vindo(a) de volta'), findsOneWidget);
    });

    testWidgets('the data-provenance chip shows the real fetch time, not the render-time clock', (tester) async {
      final holdings = [lot(ticker: 'PETR4', quantity: 100, purchasePrice: 10)];
      repository.holdingsToReturn = Holding.fromLots(holdings);
      repository.summaryToReturn = statsFromLots(holdings).summary;
      await controller.loadAll();
      final refreshedAt = controller.lastRefreshedAt!;
      final expectedTime =
          '${refreshedAt.hour.toString().padLeft(2, '0')}:${refreshedAt.minute.toString().padLeft(2, '0')}';

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('brapi.dev, hoje $expectedTime'), findsOneWidget);
    });

    testWidgets('the data-provenance chip flags stale quotes instead of implying full freshness', (tester) async {
      repository.holdingsToReturn = Holding.fromLots([
        lot(ticker: 'PETR4', priceStatus: PriceStatus.stalePurchasePrice),
      ]);
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('DADO · brapi.dev, algumas cotações indisponíveis'), findsOneWidget);
    });
  });
}
