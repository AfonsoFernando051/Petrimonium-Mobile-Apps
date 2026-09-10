/// Which onboarding screen to show. There is no Pet yet on a brand-new
/// account; an account that already has a Pet from Academy/Wallet skips
/// straight to `quickSetup` (country/currency/locale) — see
/// `Petrimonium Health.dc.html`'s `screenIsPetSetup`/`screenIsQuickSetup`.
enum OnboardingStep { petSetup, quickSetup }

enum AppTab { home, transactions, accounts, mentor }

enum AuthMode { login, signup }

/// Screen stacked above the main tab scaffold (back-navigable), mirroring
/// the prototype's `subScreen`.
enum AppSubScreen { root, profile, regionalPreferences, addDebt, addIncome }

/// Where the user is in the app: which tab, which stacked sub-screen, whether
/// the notification tray is open.
///
/// Split out of `HealthController` because routing is not the same job as
/// owning the user's financial data, and mixing them is what made that class
/// answer for eight features at once. This is deliberately *not* a
/// `ChangeNotifier`: `HealthController` owns the single notifier the widget
/// tree listens to (see `HealthScope`, and the splash-screen bug its comment
/// records), so this reports changes back through [onChanged] and the
/// notification behaviour stays exactly what it was.
final class HealthNavigationController {
  HealthNavigationController({required void Function() onChanged}) : _onChanged = onChanged;

  final void Function() _onChanged;

  AuthMode authMode = AuthMode.login;
  AppSubScreen subScreen = AppSubScreen.root;
  AppTab tab = AppTab.home;
  bool notifOpen = false;
  bool insightDismissed = false;

  void setAuthMode(AuthMode mode) {
    authMode = mode;
    _onChanged();
  }

  void openProfile() {
    subScreen = AppSubScreen.profile;
    _onChanged();
  }

  void openRegionalPreferences() {
    subScreen = AppSubScreen.regionalPreferences;
    _onChanged();
  }

  void openAccounts() {
    subScreen = AppSubScreen.root;
    tab = AppTab.accounts;
    _onChanged();
  }

  void openMentor() {
    subScreen = AppSubScreen.root;
    tab = AppTab.mentor;
    _onChanged();
  }

  void openAddDebt() {
    subScreen = AppSubScreen.addDebt;
    _onChanged();
  }

  void openAddIncome() {
    subScreen = AppSubScreen.addIncome;
    _onChanged();
  }

  void closeSubScreen() {
    subScreen = AppSubScreen.root;
    _onChanged();
  }

  void selectTab(AppTab value) {
    tab = value;
    notifOpen = false;
    _onChanged();
  }

  void toggleNotif() {
    notifOpen = !notifOpen;
    _onChanged();
  }

  void dismissInsight() {
    insightDismissed = true;
    _onChanged();
  }

  /// Reset on sign-out, so the next account never lands mid-flow in the
  /// previous one's screen.
  void reset() {
    authMode = AuthMode.login;
    subScreen = AppSubScreen.root;
    tab = AppTab.home;
    notifOpen = false;
    insightDismissed = false;
  }
}
