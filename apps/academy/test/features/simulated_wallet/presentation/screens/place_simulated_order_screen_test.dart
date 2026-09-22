import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/data/repositories/simulated_wallet_repository.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/controllers/simulated_wallet_controller.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/screens/place_simulated_order_screen.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/simulated_wallet_repository_test.dart';

void main() {
  late FakeSimulatedWalletRemoteDataSource remoteDataSource;
  late SimulatedWalletController controller;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    remoteDataSource = FakeSimulatedWalletRemoteDataSource();
    controller = SimulatedWalletController(repository: SimulatedWalletRepository(remoteDataSource: remoteDataSource));
  });

  tearDown(() => controller.dispose());

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: PlaceSimulatedOrderScreen(controller: controller),
    );
  }

  // The type grid pushes the search field (and everything below it) past
  // the default test viewport, so it starts offstage inside the ListView —
  // scroll it into view before interacting, same as a real user would.
  Future<void> revealAndEnterText(WidgetTester tester, Finder finder, String text) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, text);
  }

  Future<void> revealAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  group('PlaceSimulatedOrderScreen', () {
    testWidgets('search and reference quote preserve EUR in English', (tester) async {
      Translator.currentLanguage = 'en';
      remoteDataSource.quotesToReturn = [
        {'symbol': 'EURO', 'shortName': 'Euro asset', 'regularMarketPrice': 1234.56, 'currency': 'EUR'},
      ];
      remoteDataSource.quoteToReturn = {'symbol': 'EURO', 'regularMarketPrice': 1234.56, 'currency': 'EUR'};
      await tester.pumpWidget(buildTestableWidget());
      await revealAndEnterText(tester, find.byType(TextField, skipOffstage: false).first, 'EURO');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('€1,234.56', skipOffstage: false), findsOneWidget);
      await revealAndTap(tester, find.text('EURO', skipOffstage: false).last);
      await tester.pump();
      expect(find.textContaining('€1,234.56', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('R\$', skipOffstage: false), findsNothing);
    });

    testWidgets('shows all 6 investment-type cards, none selected before a ticker is searched', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Ações'), findsOneWidget);
      expect(find.text('R. Fixa', skipOffstage: false), findsOneWidget);
      expect(find.text('FIIs'), findsOneWidget);
      expect(find.text('Cripto'), findsOneWidget);
      expect(find.text('ETFs'), findsOneWidget);
      expect(find.text('Outros'), findsOneWidget);
    });

    testWidgets('selecting a B3 stock ticker pre-fills STOCKS via the classifier', (tester) async {
      remoteDataSource.quotesToReturn = [
        {'symbol': 'PETR4', 'shortName': 'Petrobras', 'regularMarketPrice': 30.5, 'currency': 'BRL'},
      ];
      remoteDataSource.quoteToReturn = {'symbol': 'PETR4', 'regularMarketPrice': 30.5, 'currency': 'BRL'};

      await tester.pumpWidget(buildTestableWidget());
      await revealAndEnterText(tester, find.byType(TextField, skipOffstage: false).first, 'PETR4');
      await tester.pump(const Duration(milliseconds: 400));
      await revealAndTap(tester, find.text('PETR4', skipOffstage: false).last);
      await tester.pump();

      // The STOCKS card now renders its selected check icon.
      final stocksCardIcon = tester.widget<Icon>(
        find.descendant(
          of: find.ancestor(of: find.text('Ações'), matching: find.byType(InkWell)),
          matching: find.byIcon(Icons.check_circle),
        ),
      );
      expect(stocksCardIcon.icon, Icons.check_circle);
    });

    testWidgets('confirming without picking a type for an unclassifiable ticker shows an error, never submits', (
      tester,
    ) async {
      remoteDataSource.quotesToReturn = [
        {'symbol': 'CDBBANCO', 'shortName': 'CDB Banco X', 'regularMarketPrice': 100.0, 'currency': 'BRL'},
      ];
      remoteDataSource.quoteToReturn = {'symbol': 'CDBBANCO', 'regularMarketPrice': 100.0, 'currency': 'BRL'};

      await tester.pumpWidget(buildTestableWidget());
      await revealAndEnterText(tester, find.byType(TextField, skipOffstage: false).first, 'CDBBANCO');
      await tester.pump(const Duration(milliseconds: 400));
      await revealAndTap(tester, find.text('CDBBANCO', skipOffstage: false).last);
      await tester.pump();
      await revealAndEnterText(tester, find.byType(TextField, skipOffstage: false).last, '5');
      await revealAndTap(
        tester,
        find.text(Translator.translate(AppStrings.simulatedOrderConfirmAction), skipOffstage: false),
      );
      await tester.pump();

      expect(find.text(Translator.translate(AppStrings.simulatedWalletSelectTypeError)), findsOneWidget);
      expect(controller.portfolio.positions, isEmpty);
    });

    testWidgets('confirming with a manually chosen type persists it for that ticker', (tester) async {
      remoteDataSource.quotesToReturn = [
        {'symbol': 'CDBBANCO', 'shortName': 'CDB Banco X', 'regularMarketPrice': 100.0, 'currency': 'BRL'},
      ];
      remoteDataSource.quoteToReturn = {'symbol': 'CDBBANCO', 'regularMarketPrice': 100.0, 'currency': 'BRL'};
      remoteDataSource.orderToReturn = {
        'id': 1,
        'ticker': 'CDBBANCO',
        'side': 'BUY',
        'quantity': 5.0,
        'price': 100.0,
        'total': 500.0,
        'executedAt': '2026-01-01T12:00:00Z',
        'clientOrderId': 'x',
      };

      await tester.pumpWidget(buildTestableWidget());
      await revealAndTap(tester, find.text('R. Fixa', skipOffstage: false));
      await tester.pump();
      await revealAndEnterText(tester, find.byType(TextField, skipOffstage: false).first, 'CDBBANCO');
      await tester.pump(const Duration(milliseconds: 400));
      await revealAndTap(tester, find.text('CDBBANCO', skipOffstage: false).last);
      await tester.pump();
      await revealAndEnterText(tester, find.byType(TextField, skipOffstage: false).last, '5');
      await revealAndTap(
        tester,
        find.text(Translator.translate(AppStrings.simulatedOrderConfirmAction), skipOffstage: false),
      );
      await tester.pump();
      await tester.pump();

      expect(await controller.resolveDefaultType('CDBBANCO'), InvestmentTypeEnum.FIXED_INCOME);
    });

    group('order date', () {
      // Picks the 10th of the previous month — always strictly in the past,
      // whatever day the suite runs on (a fixed "1" would be today on the 1st).
      Future<DateTime> pickDateInPreviousMonth(WidgetTester tester) async {
        await revealAndTap(
          tester,
          find.text(Translator.translate(AppStrings.simulatedOrderDateToday), skipOffstage: false),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Previous month'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('10'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        final now = DateTime.now();
        return DateTime(now.year, now.month - 1, 10);
      }

      Future<void> selectPetr4(WidgetTester tester) async {
        remoteDataSource.quotesToReturn = [
          {'symbol': 'PETR4', 'shortName': 'Petrobras', 'regularMarketPrice': 30.5, 'currency': 'BRL'},
        ];
        remoteDataSource.quoteToReturn = {'symbol': 'PETR4', 'regularMarketPrice': 30.5, 'currency': 'BRL'};
        await revealAndEnterText(tester, find.byType(TextField, skipOffstage: false).first, 'PETR4');
        await tester.pump(const Duration(milliseconds: 400));
        await revealAndTap(tester, find.text('PETR4', skipOffstage: false).last);
        await tester.pumpAndSettle();
      }

      Future<void> confirm(WidgetTester tester) async {
        await revealAndEnterText(tester, find.byType(TextField, skipOffstage: false).last, '5');
        await revealAndTap(
          tester,
          find.text(Translator.translate(AppStrings.simulatedOrderConfirmAction), skipOffstage: false),
        );
        await tester.pump();
        await tester.pump();
      }

      testWidgets('defaults to today and sends no tradeDate — an ordinary live order', (tester) async {
        await tester.pumpWidget(buildTestableWidget());
        await selectPetr4(tester);
        await confirm(tester);

        expect(remoteDataSource.lastPlacedTicker, 'PETR4');
        expect(remoteDataSource.lastPlacedTradeDate, isNull);
        expect(remoteDataSource.lastQuotedAtDate, isNull);
      });

      testWidgets('a past date shows that day\'s close and is sent as the order\'s tradeDate', (tester) async {
        remoteDataSource.quoteAtDateToReturn = {'symbol': 'PETR4', 'regularMarketPrice': 26.4, 'currency': 'BRL'};

        await tester.pumpWidget(buildTestableWidget());
        await selectPetr4(tester);
        final picked = await pickDateInPreviousMonth(tester);

        expect(remoteDataSource.lastQuotedAtDate, isNotNull);
        expect(find.textContaining('R\$ 26,40', skipOffstage: false), findsOneWidget);

        await confirm(tester);

        final expected =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        expect(remoteDataSource.lastPlacedTradeDate, expected);
      });

      testWidgets('a past date with no historical close blocks the order instead of falling back to today\'s price', (
        tester,
      ) async {
        remoteDataSource.quoteAtDateToReturn = null;

        await tester.pumpWidget(buildTestableWidget());
        await selectPetr4(tester);
        await pickDateInPreviousMonth(tester);
        await confirm(tester);

        expect(find.text(Translator.translate(AppStrings.simulatedOrderNoHistoricalQuote)), findsWidgets);
        expect(remoteDataSource.lastPlacedTicker, isNull);
      });
    });
  });
}
