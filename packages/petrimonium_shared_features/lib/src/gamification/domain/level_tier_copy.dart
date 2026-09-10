import '../../i18n/shared_strings.dart';
import 'level_tier.dart';

/// The copy key each [LevelTier] is named by.
///
/// The mapping is an ecosystem rule - a level means the same thing in every
/// product, so tier 4 must not be "Investor" in one app and something else in
/// the other. The *wording* behind these keys is still the product's, resolved
/// through its own translator; what is fixed here is which key a tier maps to.
String levelTierKey(LevelTier tier) => switch (tier) {
  LevelTier.beginner => SharedStrings.levelTierBeginner,
  LevelTier.learner => SharedStrings.levelTierLearner,
  LevelTier.explorer => SharedStrings.levelTierExplorer,
  LevelTier.investor => SharedStrings.levelTierInvestor,
  LevelTier.analyst => SharedStrings.levelTierAnalyst,
  LevelTier.strategist => SharedStrings.levelTierStrategist,
  LevelTier.specialist => SharedStrings.levelTierSpecialist,
};
