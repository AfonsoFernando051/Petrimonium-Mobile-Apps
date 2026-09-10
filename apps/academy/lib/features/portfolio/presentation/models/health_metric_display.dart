import 'package:flutter/material.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// This product's wording and iconography for each portfolio-health facet.
///
/// The scores and the facets themselves are ecosystem rules and live in
/// `petrimonium_shared_features`; only the presentation of them is here. That
/// is what keeps `PortfolioHealthCalculator` free of any Flutter import — it
/// is pure arithmetic and is tested as such.
extension HealthMetricDisplay on HealthMetricKind {
  String get label => switch (this) {
    HealthMetricKind.diversification => 'Diversificação',
    HealthMetricKind.growth => 'Crescimento',
    HealthMetricKind.incomeStability => 'Estab. de Renda',
    HealthMetricKind.dividendStrength => 'Força de Dividendos',
    HealthMetricKind.volatilityControl => 'Controle de Volatilidade',
    HealthMetricKind.longTermPotential => 'Potencial Longo Prazo',
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
