import 'package:petrimonium/features/onboarding/data/models/wallet_base_currency_enum.dart';

/// The Wallet's country/market, chosen on the quick-setup screen.
///
/// Only one value exists today — the product only has real market data for
/// B3 (see `Petrimonium-Backend`'s `BrapiInvestmentApiClient`, brapi.dev
/// only covers Brazil). This stays a real, extensible selector rather than
/// static text so adding a second market later doesn't require redesigning
/// the screen, without pretending support that doesn't exist yet.
enum WalletMarketEnum { brazilB3 }

extension WalletMarketEnumDisplay on WalletMarketEnum {
  String get flag => switch (this) {
        WalletMarketEnum.brazilB3 => '🇧🇷',
      };

  String get label => switch (this) {
        WalletMarketEnum.brazilB3 => 'Brasil · B3',
      };

  WalletBaseCurrencyEnum get defaultCurrency => switch (this) {
        WalletMarketEnum.brazilB3 => WalletBaseCurrencyEnum.brl,
      };

  static WalletMarketEnum fromName(String? name) {
    return WalletMarketEnum.values.firstWhere(
      (m) => m.name == name,
      orElse: () => WalletMarketEnum.brazilB3,
    );
  }
}
