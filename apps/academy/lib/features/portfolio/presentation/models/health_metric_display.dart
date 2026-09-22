import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// This product's wording and iconography for each portfolio-health facet.
///
/// The scores and the facets themselves are ecosystem rules and live in
/// `petrimonium_shared_features`; only the presentation of them is here. That
/// is what keeps `PortfolioHealthCalculator` free of any Flutter import — it
/// is pure arithmetic and is tested as such.
extension HealthMetricDisplay on HealthMetricKind {
  String get label => switch (this) {
    HealthMetricKind.diversification => Translator.translate(AppStrings.healthMetricDiversification),
    HealthMetricKind.growth => Translator.translate(AppStrings.healthMetricGrowth),
    HealthMetricKind.incomeStability => Translator.translate(AppStrings.healthMetricIncomeStability),
    HealthMetricKind.dividendStrength => Translator.translate(AppStrings.healthMetricDividendStrength),
    HealthMetricKind.volatilityControl => Translator.translate(AppStrings.healthMetricVolatilityControl),
    HealthMetricKind.longTermPotential => Translator.translate(AppStrings.healthMetricLongTermPotential),
  };

  IconData get icon => switch (this) {
    HealthMetricKind.diversification => Icons.hub,
    HealthMetricKind.growth => Icons.trending_up,
    HealthMetricKind.incomeStability => Icons.savings,
    HealthMetricKind.dividendStrength => Icons.paid,
    HealthMetricKind.volatilityControl => Icons.shield,
    HealthMetricKind.longTermPotential => Icons.rocket_launch,
  };
}
