import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium/features/onboarding/data/models/wallet_base_currency_enum.dart';
import 'package:petrimonium/features/onboarding/data/models/wallet_market_enum.dart';

/// Persists the user's chosen market/base-currency from the Wallet's
/// quick-setup screen. Local-only (SharedPreferences), mirroring
/// `PetPreferencesRepository`'s style — there is no backend field for this
/// yet.
class WalletMarketPreferencesRepository {
  static const _marketKey = 'wallet_market';
  static const _currencyKey = 'wallet_base_currency';

  Future<WalletMarketEnum> loadMarket() async {
    final prefs = await SharedPreferences.getInstance();
    return WalletMarketEnumDisplay.fromName(prefs.getString(_marketKey));
  }

  Future<void> saveMarket(WalletMarketEnum market) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_marketKey, market.name);
  }

  Future<WalletBaseCurrencyEnum> loadBaseCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return WalletBaseCurrencyEnumDisplay.fromName(prefs.getString(_currencyKey));
  }

  Future<void> saveBaseCurrency(WalletBaseCurrencyEnum currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.name);
  }
}
