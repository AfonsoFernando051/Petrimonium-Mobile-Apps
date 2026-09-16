import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// Pure tab-index → behavior mappings for [DashboardScreen]'s 4 bottom-nav
/// tabs (Início/Carteira/Proventos/Mentor). Wallet has no Academy tab, see
/// docs/ECOSYSTEM.md's Stage 5 note. The `dashboard` feature has no domain
/// layer of its own, so this small but real business logic (which
/// persistent-companion voice each tab gets) previously lived inline in the
/// screen; pulled out here so it's independently testable and the screen
/// only orchestrates widgets.
class DashboardTabRouter {
  DashboardTabRouter._();

  static const int homeTab = 0;
  static const int carteiraTab = 1;
  static const int passiveIncomeTab = 2;
  static const int mentorTab = 3;

  /// (`docs/PROJECT_CONTEXT.md`'s Pet Companion section, `PetContext`'s doc
  /// comment.) `PetContext.academy` is never returned here — Wallet has no
  /// Academy tab to map a companion voice to; it's still a valid
  /// destination for the pet's "learn more" action (see
  /// `DashboardScreen._handleCompanionDestination`), just not a tab.
  static PetContext petContextFor(int tabIndex) => switch (tabIndex) {
    homeTab => PetContext.home,
    carteiraTab => PetContext.portfolio,
    passiveIncomeTab => PetContext.portfolio,
    _ => PetContext.mentor,
  };

  /// Whether [tabIndex] is one of the portfolio-flavored tabs — used to
  /// decide whether the companion greeting needs the holdings count.
  static bool showsHoldingsCount(int tabIndex) =>
      tabIndex == homeTab || tabIndex == carteiraTab || tabIndex == passiveIncomeTab;
}
