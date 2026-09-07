/// The Wallet's base display currency, chosen on the quick-setup screen.
///
/// Only one value exists today because there is no real multi-currency
/// market data behind it yet (see [WalletMarketEnum]) — this stays a real,
/// extensible selector rather than static text so adding a second currency
/// later doesn't require redesigning the screen, without pretending support
/// that doesn't exist.
enum WalletBaseCurrencyEnum { brl }

extension WalletBaseCurrencyEnumDisplay on WalletBaseCurrencyEnum {
  String get code => switch (this) {
        WalletBaseCurrencyEnum.brl => 'BRL',
      };

  String get label => switch (this) {
        WalletBaseCurrencyEnum.brl => 'BRL — Real',
      };

  static WalletBaseCurrencyEnum fromName(String? name) {
    return WalletBaseCurrencyEnum.values.firstWhere(
      (c) => c.name == name,
      orElse: () => WalletBaseCurrencyEnum.brl,
    );
  }
}
