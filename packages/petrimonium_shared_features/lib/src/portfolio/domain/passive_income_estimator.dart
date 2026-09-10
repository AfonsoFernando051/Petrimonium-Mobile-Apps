import 'investment_type_enum.dart';
import 'passive_income_estimate.dart';
import 'investment_type_rules.dart';
import 'portfolio_stats.dart';

class PassiveIncomeEstimator {
  const PassiveIncomeEstimator._();

  static PassiveIncomeEstimate estimate(PortfolioStats stats) {
    if (!stats.hasHoldings) return PassiveIncomeEstimate.empty;

    double annual = 0;
    final monthlyByType = <InvestmentTypeEnum, double>{};

    for (final slice in stats.allocation) {
      final annualForType = slice.currentValue * slice.type.assumedAnnualYield;
      annual += annualForType;
      if (annualForType > 0) monthlyByType[slice.type] = annualForType / 12;
    }

    return PassiveIncomeEstimate(
      monthlyEstimate: annual / 12,
      annualEstimate: annual,
      monthlyByType: monthlyByType,
    );
  }
}
