import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';

/// Product-facing tier name for a numeric level (`docs/FEATURES.md`'s
/// "Levels" target copy table) — presentational only, derived from the real
/// number `LevelCalculator.fromXp` already computes. A level/tier name is a
/// motivational milestone, never a certification of financial competence
/// (`docs/PRODUCT_VISION.md` §9) — copy must stay generic ("Learner",
/// "Explorer"...), never imply investing skill.
///
/// The tier *boundaries* live in `petrimonium_shared_features` because global
/// level is one ecosystem-wide number; only the copy is resolved here, through
/// this product's own string catalog.
class LevelTitle {
  const LevelTitle._();

  static String forLevel(int level) {
    final key = switch (LevelTier.forLevel(level)) {
      LevelTier.beginner => AppStrings.levelTierBeginner,
      LevelTier.learner => AppStrings.levelTierLearner,
      LevelTier.explorer => AppStrings.levelTierExplorer,
      LevelTier.investor => AppStrings.levelTierInvestor,
      LevelTier.analyst => AppStrings.levelTierAnalyst,
      LevelTier.strategist => AppStrings.levelTierStrategist,
      LevelTier.specialist => AppStrings.levelTierSpecialist,
    };
    return Translator.translate(key);
  }
}
