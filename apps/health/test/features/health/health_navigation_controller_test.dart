import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_health/features/health/presentation/health_navigation_controller.dart';

/// Routing used to live on `HealthController` alongside the user's accounts
/// and transactions. These pin the transitions that were previously only
/// exercised incidentally, through widget tests.
void main() {
  late int notifications;
  late HealthNavigationController navigation;

  setUp(() {
    notifications = 0;
    navigation = HealthNavigationController(onChanged: () => notifications++);
  });

  test('starts on the home tab, at the root, signed out into login', () {
    expect(navigation.tab, AppTab.home);
    expect(navigation.subScreen, AppSubScreen.root);
    expect(navigation.authMode, AuthMode.login);
    expect(navigation.notifOpen, isFalse);
    expect(navigation.insightDismissed, isFalse);
  });

  test('every transition reports exactly one change', () {
    navigation.openProfile();
    navigation.closeSubScreen();
    navigation.selectTab(AppTab.transactions);
    navigation.toggleNotif();
    navigation.dismissInsight();
    navigation.setAuthMode(AuthMode.signup);

    expect(
      notifications,
      6,
      reason:
          'the widget tree listens through HealthController; a missed '
          'call is a screen that does not repaint',
    );
  });

  test('opening a stacked sub-screen leaves the tab underneath alone', () {
    navigation.selectTab(AppTab.accounts);
    navigation.openProfile();

    expect(navigation.subScreen, AppSubScreen.profile);
    expect(navigation.tab, AppTab.accounts, reason: 'the sub-screen is stacked, not a tab change');

    navigation.closeSubScreen();
    expect(navigation.subScreen, AppSubScreen.root);
    expect(navigation.tab, AppTab.accounts);
  });

  test('openAccounts and openMentor switch tab and pop back to the root', () {
    navigation.openProfile();
    navigation.openAccounts();
    expect(navigation.tab, AppTab.accounts);
    expect(navigation.subScreen, AppSubScreen.root);

    navigation.openProfile();
    navigation.openMentor();
    expect(navigation.tab, AppTab.mentor);
    expect(navigation.subScreen, AppSubScreen.root);
  });

  test('changing tab closes the notification tray', () {
    navigation.toggleNotif();
    expect(navigation.notifOpen, isTrue);

    navigation.selectTab(AppTab.transactions);
    expect(navigation.notifOpen, isFalse, reason: 'the tray belongs to the tab it was opened over');
  });

  test('reset returns every field to its signed-out value', () {
    navigation.setAuthMode(AuthMode.signup);
    navigation.selectTab(AppTab.mentor);
    navigation.openAddDebt();
    navigation.toggleNotif();
    navigation.dismissInsight();

    navigation.reset();

    expect(navigation.authMode, AuthMode.login);
    expect(navigation.tab, AppTab.home);
    expect(navigation.subScreen, AppSubScreen.root);
    expect(navigation.notifOpen, isFalse);
    expect(
      navigation.insightDismissed,
      isFalse,
      reason: 'the next account must not inherit the previous one\'s dismissed insight',
    );
  });

  test('reset does not notify: logout notifies once for the whole sign-out', () {
    navigation.openAddIncome();
    final before = notifications;

    navigation.reset();

    expect(notifications, before);
  });
}
