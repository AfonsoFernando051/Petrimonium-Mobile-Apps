import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium/features/onboarding/data/models/wallet_base_currency_enum.dart';
import 'package:petrimonium/features/onboarding/data/models/wallet_market_enum.dart';
import 'package:petrimonium/features/onboarding/data/repositories/wallet_market_preferences_repository.dart';

void main() {
  late WalletMarketPreferencesRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = WalletMarketPreferencesRepository();
  });

  group('market', () {
    test('defaults to brazilB3 when nothing is saved', () async {
      expect(await repository.loadMarket(), WalletMarketEnum.brazilB3);
    });

    test('round-trips a saved market', () async {
      await repository.saveMarket(WalletMarketEnum.brazilB3);
      expect(await repository.loadMarket(), WalletMarketEnum.brazilB3);
    });

    test('falls back to brazilB3 for an unrecognized stored value', () async {
      SharedPreferences.setMockInitialValues({'wallet_market': 'not_a_real_market'});
      expect(await repository.loadMarket(), WalletMarketEnum.brazilB3);
    });
  });

  group('base currency', () {
    test('defaults to brl when nothing is saved', () async {
      expect(await repository.loadBaseCurrency(), WalletBaseCurrencyEnum.brl);
    });

    test('round-trips a saved currency', () async {
      await repository.saveBaseCurrency(WalletBaseCurrencyEnum.brl);
      expect(await repository.loadBaseCurrency(), WalletBaseCurrencyEnum.brl);
    });

    test('falls back to brl for an unrecognized stored value', () async {
      SharedPreferences.setMockInitialValues({'wallet_base_currency': 'not_a_real_currency'});
      expect(await repository.loadBaseCurrency(), WalletBaseCurrencyEnum.brl);
    });
  });
}
