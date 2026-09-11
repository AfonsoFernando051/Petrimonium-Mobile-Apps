import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/features/asset_details/domain/entities/asset_details.dart';
import 'package:petrimonium_wallet/features/asset_details/domain/entities/user_position.dart';
import 'package:petrimonium_wallet/features/asset_details/presentation/widgets/user_position_card.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

void main() {
  Widget buildTestableWidget(AssetDetails asset) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: UserPositionCard(asset: asset)),
    );
  }

  group('UserPositionCard', () {
    testWidgets('renders nothing when the asset has no user position', (tester) async {
      const asset = AssetDetails(ticker: 'PETR4');

      await tester.pumpWidget(buildTestableWidget(asset));

      expect(find.text('SUA POSIÇÃO'), findsNothing);
    });

    testWidgets('renders a positive P/L in green with a + sign', (tester) async {
      const asset = AssetDetails(
        ticker: 'PETR4',
        userPosition: UserPosition(
          quantity: 100,
          averagePrice: 20,
          investedValue: 2000,
          currentValue: 2500,
          unrealizedGain: 500,
          unrealizedGainPercent: 25,
          portfolioWeight: 12.34,
          priceStatus: PriceStatus.live,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(asset));

      expect(find.text('SUA POSIÇÃO'), findsOneWidget);
      expect(find.text('R\$ 2.500'), findsOneWidget);
      expect(find.text('+R\$ 500'), findsOneWidget);
      expect(find.text('(+25.00%)'), findsOneWidget);
      expect(find.text('12.3%'), findsOneWidget);
      expect(find.text('da carteira'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);

      // Stats grid
      expect(find.text('Cotas'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
      expect(find.text('R\$ 20,00'), findsOneWidget);
      expect(find.text('Investido'), findsOneWidget);
      expect(find.text('R\$ 2.000'), findsOneWidget);
    });

    testWidgets('renders a negative P/L in the error color without a + sign, and fractional quantity', (tester) async {
      const asset = AssetDetails(
        ticker: 'PETR4',
        userPosition: UserPosition(
          quantity: 10.5,
          averagePrice: 20,
          investedValue: 210,
          currentValue: 180,
          unrealizedGain: -30,
          unrealizedGainPercent: -14.29,
          portfolioWeight: 5,
          priceStatus: PriceStatus.live,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(asset));

      expect(find.text('-R\$ 30'), findsOneWidget);
      expect(find.text('(-14.29%)'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.text('10.50'), findsOneWidget);
    });

    testWidgets('shows an unavailable badge instead of a fake 0% gain when the price is stale', (tester) async {
      const asset = AssetDetails(
        ticker: 'PETR4',
        userPosition: UserPosition(
          quantity: 10,
          averagePrice: 20,
          investedValue: 200,
          currentValue: 200,
          unrealizedGain: 0,
          unrealizedGainPercent: 0,
          portfolioWeight: 5,
          priceStatus: PriceStatus.stalePurchasePrice,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(asset));

      expect(find.text('SEM COTAÇÃO'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
      expect(find.text('(+0.00%)'), findsNothing);
    });

    testWidgets('shows a not-quoted badge for fixed income lots', (tester) async {
      const asset = AssetDetails(
        ticker: 'TESOURO-SELIC',
        userPosition: UserPosition(
          quantity: 10,
          averagePrice: 100,
          investedValue: 1000,
          currentValue: 1000,
          unrealizedGain: 0,
          unrealizedGainPercent: 0,
          portfolioWeight: 5,
          priceStatus: PriceStatus.notQuoted,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(asset));

      expect(find.text('NÃO COTADO'), findsOneWidget);
    });
  });
}
