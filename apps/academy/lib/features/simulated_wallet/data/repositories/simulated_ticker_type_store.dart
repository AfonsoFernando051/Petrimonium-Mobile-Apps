import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// Remembers which [InvestmentTypeEnum] the student picked for a ticker when
/// placing a simulated order — the backend's `simulated_portfolio` has no
/// type column at all (unlike Wallet's real `investments` table, where the
/// user's choice is persisted server-side per lot), so this is the only
/// place that choice lives.
///
/// Keyed by ticker alone, never by portfolio — a ticker's asset class is a
/// fact about the ticker (`PETR4` is always a stock), not about a specific
/// simulated position, so resetting the wallet must never forget it.
class SimulatedTickerTypeStore {
  static const _keyPrefix = 'simulated_wallet_ticker_type_';

  Future<InvestmentTypeEnum?> getStoredType(String ticker) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_keyPrefix${ticker.toUpperCase()}');
    if (stored == null) return null;
    for (final type in InvestmentTypeEnum.values) {
      if (type.name == stored) return type;
    }
    return null;
  }

  Future<void> setType(String ticker, InvestmentTypeEnum type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix${ticker.toUpperCase()}', type.name);
  }
}
