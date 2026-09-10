import 'investment_type_enum.dart';

/// The heuristics that describe how an asset class *behaves*, as opposed to
/// how a product draws it.
///
/// This is the `LevelTier` split applied to investment types: the numbers
/// below are ecosystem facts — the same target allocation and the same
/// assumed yield have to hold in Academy's simulated portfolio and in
/// Wallet's real one, or the two products would tell the same user two
/// different things about the same asset class. The label, short label,
/// icon and color are *not* here: those are product copy and product
/// branding, and each app keeps its own `InvestmentTypeDisplay`.
extension InvestmentTypeRules on InvestmentTypeEnum {
  /// Suggested balanced-portfolio target, expressed as a percent of total
  /// current value. This is a simple, editable-in-future heuristic (not a
  /// personalized recommendation engine) used to power the allocation
  /// "ideal vs current" comparison and rebalance insights.
  double get idealTargetPercent => switch (this) {
    InvestmentTypeEnum.STOCKS => 35,
    InvestmentTypeEnum.FIXED_INCOME => 30,
    InvestmentTypeEnum.REAL_ESTATE => 15,
    InvestmentTypeEnum.FUNDS => 12,
    InvestmentTypeEnum.CRYPTO => 5,
    InvestmentTypeEnum.OTHERS => 3,
  };

  /// Assumed average annual yield used only to *estimate* passive income,
  /// since no real dividend/coupon data source exists yet. Always surfaced
  /// to the user as "estimated", never presented as a confirmed payment.
  double get assumedAnnualYield => switch (this) {
    InvestmentTypeEnum.STOCKS => 0.05,
    InvestmentTypeEnum.FIXED_INCOME => 0.11,
    InvestmentTypeEnum.REAL_ESTATE => 0.08,
    InvestmentTypeEnum.FUNDS => 0.04,
    InvestmentTypeEnum.CRYPTO => 0.0,
    InvestmentTypeEnum.OTHERS => 0.0,
  };
}
