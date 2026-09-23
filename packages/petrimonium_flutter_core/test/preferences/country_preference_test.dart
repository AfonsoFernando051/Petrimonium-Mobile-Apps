import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => CountryPreference.debugReset());

  test('loads a supported saved country', () async {
    SharedPreferences.setMockInitialValues({'auth_email': 'a@example.com', 'account_country::a@example.com': 'PT'});

    await CountryPreference.load();

    expect(CountryPreference.current, 'PT');
  });

  test('ignores a saved country that is no longer supported', () async {
    SharedPreferences.setMockInitialValues({'auth_email': 'a@example.com', 'account_country::a@example.com': 'US'});

    await CountryPreference.load();

    expect(CountryPreference.current, isNull);
  });

  test('setCountry rejects an unsupported code without changing the current value', () async {
    SharedPreferences.setMockInitialValues({'auth_email': 'a@example.com'});
    await CountryPreference.setCountry('BR');

    await CountryPreference.setCountry('US');

    expect(CountryPreference.current, 'BR');
  });

  // The leak this scoping exists to prevent: `account_country` used to be a single global key,
  // so a device shared between two accounts served the second one whatever the first had chosen.
  // `load()` runs once in main() and nothing re-runs it after a login, and logout deliberately
  // keeps preferences (see UserScopedPrefs) — so without a per-account scope the wrong country
  // survived both a logout/login switch and a full app restart, until the user happened to open
  // Settings and trigger a server sync.
  test('one account never reads another account\'s country on the same device', () async {
    SharedPreferences.setMockInitialValues({'auth_email': 'first@example.com'});
    await CountryPreference.setCountry('PT');

    // Logout clears auth_email but deliberately leaves preferences behind; a second account
    // then logs in on the same device.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_email', 'second@example.com');
    CountryPreference.debugReset();

    await CountryPreference.load();

    expect(CountryPreference.current, isNull);
  });

  test('each account keeps its own country across a switch back', () async {
    SharedPreferences.setMockInitialValues({'auth_email': 'first@example.com'});
    await CountryPreference.setCountry('PT');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_email', 'second@example.com');
    CountryPreference.debugReset();
    await CountryPreference.setCountry('BR');

    await prefs.setString('auth_email', 'first@example.com');
    CountryPreference.debugReset();
    await CountryPreference.load();

    expect(CountryPreference.current, 'PT');
  });

  // Upgrade path: everyone already on the app has a value under the old global key. Without
  // adopting it, the scoping change would read as "country not chosen yet" for every existing
  // user until they reopened Settings.
  test('adopts a value left under the old global key into the logged-in account', () async {
    SharedPreferences.setMockInitialValues({'auth_email': 'a@example.com', 'account_country': 'PT'});

    await CountryPreference.load();

    expect(CountryPreference.current, 'PT');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('account_country::a@example.com'), 'PT');
    expect(prefs.getString('account_country'), isNull, reason: 'the leaky global key must not survive');
  });

  // Adopting into the anonymous scope would hand the last user's country to whoever opens the
  // app next while logged out — the very leak being closed.
  test('does not adopt the old global key while logged out', () async {
    SharedPreferences.setMockInitialValues({'account_country': 'PT'});

    await CountryPreference.load();

    expect(CountryPreference.current, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('account_country'), 'PT', reason: 'kept for the next real login to adopt');
  });

  test('a later real login still adopts the value left by the logged-out pass', () async {
    SharedPreferences.setMockInitialValues({'account_country': 'BR'});
    await CountryPreference.load();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_email', 'a@example.com');
    CountryPreference.debugReset();
    await CountryPreference.load();

    expect(CountryPreference.current, 'BR');
  });
}
