/// The motivational tier a numeric level falls into.
///
/// The *boundaries* are shared: a level-12 user is an explorer in Academy, in
/// Wallet and in Health, because global level is one ecosystem-wide number
/// (the backend owns the XP ledger that produces it). The *copy* is not
/// shared - each product translates the tier through its own string catalog,
/// which is why this returns an enum and not a label.
///
/// A tier is a motivational milestone, never a certification of financial
/// competence. Copy must stay generic ("Learner", "Explorer"), and must never
/// imply investing skill.
enum LevelTier {
  beginner,
  learner,
  explorer,
  investor,
  analyst,
  strategist,
  specialist;

  /// Same boundaries the products already used, unchanged.
  static LevelTier forLevel(int level) => switch (level) {
        < 5 => LevelTier.beginner,
        < 10 => LevelTier.learner,
        < 15 => LevelTier.explorer,
        < 20 => LevelTier.investor,
        < 30 => LevelTier.analyst,
        < 40 => LevelTier.strategist,
        _ => LevelTier.specialist,
      };
}
