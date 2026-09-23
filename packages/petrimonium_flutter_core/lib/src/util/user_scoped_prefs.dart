import 'package:shared_preferences/shared_preferences.dart';

/// Scopes a local-only `SharedPreferences` key to the currently logged-in
/// account, so switching accounts on the same device never leaks one user's
/// locally-cached progress (Academy completions, achievements, ...) into
/// another user's session.
///
/// The email saved by `AuthRepository` under the `auth_email` key (read
/// directly here rather than via `AuthRepository`, to avoid a dependency
/// from low-level local-cache repositories onto the auth feature) is the
/// only stable per-account identifier available client-side — there is no
/// decoded JWT claim or numeric user id cached locally. `logout()` clears
/// `auth_email` but deliberately leaves the scoped data behind, so a user
/// who logs back in later finds their progress exactly as they left it.
class UserScopedPrefs {
  static const _authEmailKey = 'auth_email';

  /// Falls back to this scope before any login has ever happened on this
  /// device (or if `auth_email` is somehow missing/empty) — callers must
  /// never operate on a null/empty scope.
  static const _anonymousScope = 'anonymous';

  /// Appends the current account's scope to [baseKey], e.g.
  /// `academy_completed_lesson_ids` becomes
  /// `academy_completed_lesson_ids::user@example.com`.
  static Future<String> key(String baseKey) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_authEmailKey);
    final scope = (email == null || email.isEmpty) ? _anonymousScope : email;
    return '$baseKey::$scope';
  }

  /// Reads [baseKey] from the current account's scope.
  ///
  /// A preference that used to be stored unscoped is adopted into the current
  /// account's scope the first time this runs, and the old global key removed —
  /// otherwise moving a key onto scoping would read as "never chosen" for every
  /// user already on the app, until they happened to reopen the screen that
  /// re-syncs it from the backend.
  ///
  /// The adoption deliberately does not happen while logged out: the anonymous
  /// scope is shared by everyone who opens the app without a session, so
  /// handing it the last account's value would recreate exactly the cross-account
  /// leak that scoping exists to close. The old key is left in place for the next
  /// real login to adopt instead.
  static Future<String?> readString(String baseKey) async {
    final prefs = await SharedPreferences.getInstance();
    final scopedKey = await key(baseKey);

    final scoped = prefs.getString(scopedKey);
    if (scoped != null) return scoped;

    if (scopedKey == '$baseKey::$_anonymousScope') return null;

    final legacy = prefs.getString(baseKey);
    if (legacy == null) return null;

    await prefs.setString(scopedKey, legacy);
    await prefs.remove(baseKey);
    return legacy;
  }

  /// Writes [value] under [baseKey] in the current account's scope.
  static Future<void> writeString(String baseKey, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await key(baseKey), value);
  }
}
