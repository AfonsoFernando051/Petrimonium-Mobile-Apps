import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/features/investment/data/models/asset_registration_model.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/investment/presentation/widgets/added_asset_tile.dart';

void main() {
  Widget buildTestableWidget(AssetRegistrationModel asset, {VoidCallback? onEdit, VoidCallback? onRemove}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: ReorderableListView(
          onReorder: (_, _) {},
          children: [
            AddedAssetTile(
              key: const ValueKey('tile'),
              index: 0,
              asset: asset,
              onEdit: onEdit ?? () {},
              onRemove: onRemove ?? () {},
            ),
          ],
        ),
      ),
    );
  }

  group('AddedAssetTile', () {
    testWidgets('renders the uppercased ticker and formatted quantity/price for a whole-unit asset', (WidgetTester tester) async {
      final asset = AssetRegistrationModel(
        name: 'petr4',
        quantity: 10,
        purchasePrice: 25.5,
        purchaseDate: '2024-01-01',
        type: InvestmentTypeEnum.STOCKS,
      );

      await tester.pumpWidget(buildTestableWidget(asset));
      await tester.pump();

      expect(find.text('PETR4'), findsOneWidget);
      expect(find.textContaining('10 un'), findsOneWidget);
    });

    testWidgets('shows the raw fractional quantity for a non-whole-unit asset', (WidgetTester tester) async {
      final asset = AssetRegistrationModel(
        name: 'btc',
        quantity: 0.5,
        purchasePrice: 300000,
        purchaseDate: '2024-01-01',
        type: InvestmentTypeEnum.CRYPTO,
      );

      await tester.pumpWidget(buildTestableWidget(asset));
      await tester.pump();

      expect(find.textContaining('0.5 un'), findsOneWidget);
    });

    testWidgets('fires onEdit and onRemove when their icon buttons are tapped', (WidgetTester tester) async {
      var edited = false;
      var removed = false;
      final asset = AssetRegistrationModel(
        name: 'petr4',
        quantity: 10,
        purchasePrice: 25.5,
        purchaseDate: '2024-01-01',
        type: InvestmentTypeEnum.STOCKS,
      );

      await tester.pumpWidget(buildTestableWidget(
        asset,
        onEdit: () => edited = true,
        onRemove: () => removed = true,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(edited, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      expect(removed, isTrue);
    });
  });
}
