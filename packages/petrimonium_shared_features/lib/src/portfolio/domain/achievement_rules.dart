import 'investment_type_enum.dart';
import 'passive_income_estimator.dart';
import 'portfolio_stats.dart';

/// One achievement's *rule*: its id, what it grants, and what qualifies for
/// it. Deliberately carries no title, description or icon — see
/// [AchievementRules].
class AchievementRule {
  final String id;
  final int xpReward;
  final bool Function(PortfolioStats) qualifies;

  const AchievementRule({required this.id, required this.xpReward, required this.qualifies});
}

/// The achievement rules, shared by every product that shows achievements.
///
/// Ids, XP rewards and conditions must stay in sync with the backend's Java
/// `AchievementCatalog`
/// (Petrimonium-Backend/.../application/gamification/achievement), which is
/// authoritative for a saved portfolio: it actually grants XP and persists
/// unlocks. These exist to *preview* what would unlock for assets the user
/// is still typing in (nothing for the backend to evaluate yet).
///
/// Copy and iconography are not here. Each app owns an `AchievementCatalog`
/// that joins these rules with its own wording — the `LevelTier` split, and
/// the reason sharing this did not require deciding whose copy wins.
///
/// Note: the original brief also mentions a "Global Investor" achievement,
/// but the backend's `InvestmentType` enum has no "international" category
/// to honestly evaluate that against — it's omitted here rather than faked.
abstract final class AchievementRules {
  /// Declaration order is display order; products render the catalog in this
  /// sequence.
  static final List<AchievementRule> all = [
    AchievementRule(
      id: 'first_investment',
      // DECISION-027: XP must never reward investment activity, only
      // learning/practice behavior. Kept as a milestone for flavor, but
      // grants no XP.
      xpReward: 0,
      qualifies: (s) => s.hasHoldings,
    ),
    AchievementRule(
      id: 'first_dividend',
      // DECISION-014: XP must never reward passive-income/wealth signals.
      // Kept as a milestone for flavor, but grants no XP.
      xpReward: 0,
      qualifies: (s) => PassiveIncomeEstimator.estimate(s).monthlyEstimate > 0,
    ),
    AchievementRule(
      id: 'positive_return',
      // DECISION-014: XP must never reward investment profit. Kept as a
      // milestone for flavor, but grants no XP.
      xpReward: 0,
      qualifies: (s) => s.summary.totalGain > 0,
    ),
    AchievementRule(
      id: 'portfolio_10k',
      // DECISION-014: XP must never reward wealth/portfolio size. Kept as a
      // milestone for flavor, but grants no XP.
      xpReward: 0,
      qualifies: (s) => s.summary.currentValue >= 10000,
    ),
    AchievementRule(
      id: 'portfolio_50k',
      // DECISION-014: XP must never reward wealth/portfolio size. Kept as a
      // milestone for flavor, but grants no XP.
      xpReward: 0,
      qualifies: (s) => s.summary.currentValue >= 50000,
    ),
    AchievementRule(
      id: 'diversification_master',
      // DECISION-027: XP must never reward investment activity, only
      // learning/practice behavior. Kept as a milestone for flavor, but
      // grants no XP.
      xpReward: 0,
      qualifies: (s) => s.distinctTypeCount >= 4,
    ),
    AchievementRule(
      id: 'etf_collector',
      // DECISION-027: XP must never reward investment activity, only
      // learning/practice behavior. Kept as a milestone for flavor, but
      // grants no XP.
      xpReward: 0,
      qualifies: (s) => s.holdings.where((h) => h.type == InvestmentTypeEnum.FUNDS).length >= 3,
    ),
    AchievementRule(
      id: 'hundred_days',
      // DECISION-027: XP must never reward investment activity, only
      // learning/practice behavior. Kept as a milestone for flavor, but
      // grants no XP.
      xpReward: 0,
      qualifies: (s) {
        final first = s.firstPurchaseDate;
        return first != null && DateTime.now().difference(first).inDays >= 100;
      },
    ),
    AchievementRule(
      id: 'long_term_investor',
      // DECISION-027: XP must never reward investment activity, only
      // learning/practice behavior. Kept as a milestone for flavor, but
      // grants no XP.
      xpReward: 0,
      qualifies: (s) {
        final first = s.firstPurchaseDate;
        return first != null && DateTime.now().difference(first).inDays >= 365;
      },
    ),
    AchievementRule(
      id: 'dividend_hunter',
      // DECISION-014: XP must never reward passive-income/wealth signals.
      // Kept as a milestone for flavor, but grants no XP.
      xpReward: 0,
      qualifies: (s) => PassiveIncomeEstimator.estimate(s).annualEstimate >= 1000,
    ),
  ];

  /// XP preview for a set of achievement ids — used only for the unlock
  /// celebration overlay and the pre-save onboarding preview. Pet evolution
  /// itself is fed by the backend's real total XP
  /// (`GamificationSummary.totalXp`), never by this local sum.
  static int totalXpFor(Set<String> unlockedIds) =>
      all.where((d) => unlockedIds.contains(d.id)).fold(0, (sum, d) => sum + d.xpReward);

  /// IDs whose condition is met *right now* — the caller persists any of
  /// these not already in its stored unlocked set.
  static Set<String> qualifiedIds(PortfolioStats stats) =>
      all.where((d) => d.qualifies(stats)).map((d) => d.id).toSet();
}
