import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/features/asset_details/presentation/widgets/purchase_history_card.dart';
import 'package:petrimonium_wallet/features/investment/data/models/asset_registration_model.dart';
import 'package:petrimonium_wallet/features/investment/data/repositories/investment_repository.dart';
import 'package:petrimonium_wallet/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../../../portfolio/presentation/controllers/portfolio_controller_test.dart';

class MockInvestmentRepository extends Mock implements InvestmentRepository {}

void main() {
  late MockInvestmentRepository investmentRepository;
  late PortfolioController controller;
  late bool lotChangedCalled;

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
  final holding = Holding.fromLots([lot]).first;

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
    investmentRepository = MockInvestmentRepository();
    lotChangedCalled = false;
    controller = PortfolioController(
      repository: FakePortfolioRepository(),
      achievementsLocalRepository: FakeAchievementsLocalRepository(),
      achievementsRepository: FakeAchievementsRepository(),
      gamificationRepository: FakeGamificationRepository(),
      missionsRepository: FakeMissionsRepository(),
    );
    DI.investmentRepository = investmentRepository;
  });

  tearDown(() => controller.dispose());

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: PurchaseHistoryCard(
          holding: holding,
          controller: controller,
          onLotChanged: () => lotChangedCalled = true,
        ),
      ),
    );
  }

  group('PurchaseHistoryCard — delete', () {
    testWidgets('confirming the dialog deletes the lot, refreshes and calls onLotChanged', (tester) async {
      when(() => investmentRepository.deleteInvestment(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle();

      // The confirmation dialog itself.
      expect(find.text('Excluir este lote?'), findsOneWidget);

      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle();

      verify(() => investmentRepository.deleteInvestment(7)).called(1);
      expect(lotChangedCalled, isTrue);
    });

    testWidgets('canceling the dialog never calls deleteInvestment', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => investmentRepository.deleteInvestment(any()));
      expect(lotChangedCalled, isFalse);
    });

    testWidgets('a failed delete shows an error and does not call onLotChanged', (tester) async {
      when(() => investmentRepository.deleteInvestment(any())).thenThrow(Exception('Investment not found: 7'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Não foi possível excluir o lote'), findsOneWidget);
      expect(lotChangedCalled, isFalse);
    });
  });

  group('PurchaseHistoryCard — edit', () {
    testWidgets('tapping Editar opens AddAssetScreen pre-filled with this lot', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.byType(AddAssetScreen), findsOneWidget);
      expect(find.text('Editar ativo'), findsWidgets);
    });

    testWidgets('a successful edit (pop true) calls onLotChanged', (tester) async {
      when(() => investmentRepository.updateInvestment(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(GameButton));
      await tester.tap(find.byType(GameButton), warnIfMissed: false);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(lotChangedCalled, isTrue);
    });
  });
}
