import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import 'package:petrimonium_academy/core/utils/translator.dart';

/// Product-facing tier name for a numeric level (`docs/FEATURES.md`'s
/// "Levels" target copy table) — presentational only, derived from the real
/// number `LevelCalculator.fromXp` already computes. A level/tier name is a
/// motivational milestone, never a certification of financial competence
/// (`docs/PRODUCT_VISION.md` §9) — copy must stay generic ("Learner",
/// "Explorer"...), never imply investing skill.
///
/// The tier *boundaries* live in `petrimonium_shared_features`, and so does
/// the tier→key mapping ([levelTierKey]), because global level is one
/// ecosystem-wide number; only the wording is resolved here, through this
/// product's own string catalog.
class LevelTitle {
  const LevelTitle._();

  static String forLevel(int level) => Translator.translate(levelTierKey(LevelTier.forLevel(level)));
}
