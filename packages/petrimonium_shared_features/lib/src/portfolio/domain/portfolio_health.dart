/// Health-score band — presentation reads this instead of embedding its own
/// `score >= N` thresholds, so the "what counts as strong/moderate/weak"
/// business rule lives in one place (here) rather than being re-decided by
/// every widget that renders a score.
enum HealthTier { strong, moderate, weak }

/// Which facet of portfolio health a [HealthMetric] measures.
///
/// The facet is identity; its label and icon are not. Those are product copy
/// and product branding, so each app maps this enum to its own wording — the
/// same split `LevelTier` uses. Keeping the enum here is what lets the
/// scoring live in a package with no Flutter dependency at all.
enum HealthMetricKind {
  diversification,
  growth,
  incomeStability,
  dividendStrength,
  volatilityControl,
  longTermPotential,
}

/// One 0-100 facet of portfolio health (shown as a radar axis + progress bar).
class HealthMetric {
  final HealthMetricKind kind;
  final double score;

  const HealthMetric({required this.kind, required this.score});

  /// Per-metric band. Deliberately a lower "moderate" floor (45) than
  /// [PortfolioHealth.tier]'s (50) — a single weak facet shouldn't read as
  /// flatly "poor" the way a weak overall score should.
  HealthTier get tier {
    if (score >= 75) return HealthTier.strong;
    if (score >= 45) return HealthTier.moderate;
    return HealthTier.weak;
  }
}

/// The full "Portfolio Health" verdict: an overall 0-100 score/letter grade
/// plus the individual facets that compose it. Computed purely client-side
/// by `PortfolioHealthCalculator` from real holdings/allocation data — there
/// is no such scoring model in the backend or product docs, so this is a
/// deliberately transparent, explainable heuristic rather than a black-box
/// "AI score".
class PortfolioHealth {
  final double overallScore;
  final List<HealthMetric> metrics;

  const PortfolioHealth({required this.overallScore, required this.metrics});

  static const empty = PortfolioHealth(overallScore: 0, metrics: []);

  String get grade {
    if (overallScore >= 90) return 'S';
    if (overallScore >= 75) return 'A';
    if (overallScore >= 60) return 'B';
    if (overallScore >= 40) return 'C';
    return 'D';
  }

  HealthTier get tier {
    if (overallScore >= 75) return HealthTier.strong;
    if (overallScore >= 50) return HealthTier.moderate;
    return HealthTier.weak;
  }
}
