import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/screens/first_value_screen.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../controllers/portfolio_controller_test.dart';

void main() {
  late FakePortfolioRepository portfolioRepository;
  late PortfolioController controller;

  final lot = InvestmentLot(
    id: 1,
    ticker: 'PETR4',
    type: InvestmentTypeEnum.STOCKS,
    quantity: 10,
    purchasePrice: 25,
    purchaseDate: DateTime(2024, 1, 1),
    currentPrice: 30,
    investedValue: 250,
    currentValue: 300,
  );

  setUp(() async {
    portfolioRepository = FakePortfolioRepository();
    portfolioRepository.holdingsToReturn = Holding.fromLots([lot]);
    portfolioRepository.summaryToReturn = const PortfolioSummary(
      currentValue: 300,
      investedCapital: 250,
      totalGain: 50,
      totalGainPercent: 20,
      totalAssets: 1,
    );
    portfolioRepository.allocationToReturn = const [
      AllocationSlice(type: InvestmentTypeEnum.STOCKS, currentValue: 300, portfolioPercent: 100),
    ];
    controller = PortfolioController(
      repository: portfolioRepository,
      achievementsLocalRepository: FakeAchievementsLocalRepository(),
      achievementsRepository: FakeAchievementsRepository(),
      gamificationRepository: FakeGamificationRepository(),
      missionsRepository: FakeMissionsRepository(),
    );
    await controller.refresh();
  });

  tearDown(() => controller.dispose());

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: FirstValueScreen(controller: controller),
    );
  }

  group('FirstValueScreen', () {
    testWidgets('shows the title, total wealth, the one holding and the CTA', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Sua carteira, pela primeira vez'), findsOneWidget);
      // Appears twice: the total-wealth figure and the one holding's value,
      // which happen to coincide here since it's the portfolio's only lot.
      expect(find.text('R\$ 300,00'), findsWidgets);
      expect(find.textContaining('PETR4'), findsOneWidget);
      expect(find.text('Ver minha carteira'), findsOneWidget);
    });

    testWidgets('does not show wealth-evolution or wealth-change cards (no history yet)', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // FirstValueScreen is deliberately narrower than the full dashboard —
      // no evolution/change cards, since a single just-registered lot has no
      // history to explain yet.
      expect(find.textContaining('Aportes'), findsNothing);
      expect(find.textContaining('Rendimentos'), findsNothing);
    });

    testWidgets('tapping the CTA pops the screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => FirstValueScreen(controller: controller))),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(FirstValueScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Ver minha carteira'));
      await tester.tap(find.text('Ver minha carteira'));
      await tester.pumpAndSettle();

      expect(find.byType(FirstValueScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
