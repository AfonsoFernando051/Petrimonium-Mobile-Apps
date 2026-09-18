import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/simulated_wallet/data/repositories/simulated_ticker_type_store.dart';

void main() {
  late SimulatedTickerTypeStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = SimulatedTickerTypeStore();
  });

  group('SimulatedTickerTypeStore', () {
    test('a ticker with no stored type returns null', () async {
      expect(await store.getStoredType('PETR4'), isNull);
    });

    test('remembers a type set for a ticker', () async {
      await store.setType('PETR4', InvestmentTypeEnum.STOCKS);

      expect(await store.getStoredType('PETR4'), InvestmentTypeEnum.STOCKS);
    });

    test('is case-insensitive on the ticker', () async {
      await store.setType('petr4', InvestmentTypeEnum.STOCKS);

      expect(await store.getStoredType('PETR4'), InvestmentTypeEnum.STOCKS);
    });

    test('overwriting a ticker\'s type replaces the previous one', () async {
      await store.setType('HGLG11', InvestmentTypeEnum.REAL_ESTATE);
      await store.setType('HGLG11', InvestmentTypeEnum.FUNDS);

      expect(await store.getStoredType('HGLG11'), InvestmentTypeEnum.FUNDS);
    });

    test('different tickers are stored independently', () async {
      await store.setType('PETR4', InvestmentTypeEnum.STOCKS);
      await store.setType('HGLG11', InvestmentTypeEnum.REAL_ESTATE);

      expect(await store.getStoredType('PETR4'), InvestmentTypeEnum.STOCKS);
      expect(await store.getStoredType('HGLG11'), InvestmentTypeEnum.REAL_ESTATE);
    });
  });
}
