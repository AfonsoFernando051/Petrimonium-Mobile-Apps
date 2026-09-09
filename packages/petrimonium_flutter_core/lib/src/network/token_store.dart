import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage contract for the access/refresh token pair behind [ApiClient].
///
/// Pulled out as an interface (rather than `ApiClient` talking to
/// `FlutterSecureStorage` directly) so a repository that persists a token
/// pair returned from a call the client didn't make itself — a login or
/// register response reached through `ApiClient.unauthenticatedPost` — can
/// reach the same storage `ApiClient` uses for its own refresh flow, via
/// `ApiClient.tokenStore`, instead of reopening the platform keystore under
/// a second, disconnected key.
abstract interface class TokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);

  /// Saves both halves of a login/refresh response's token pair together —
  /// the two are always issued and consumed as a pair, never independently.
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> clearAccessToken();
  Future<void> clearRefreshToken();
  Future<void> clear();
}

/// Default [TokenStore], backed by the platform keystore/keychain rather
/// than `shared_preferences` (which persists as unencrypted plaintext on
/// disk) — these values grant full account access.
///
/// [accessKey]/[refreshKey] are overridable so each product can keep its own
/// storage namespace — migrating an app from a bespoke client onto this one
/// without renaming its keys means an already-installed user's session
/// survives the upgrade instead of forcing a re-login.
///
/// [readTimeout] guards a read against a platform keyring that never
/// answers — e.g. a locked GNOME keyring raising an unlock prompt with no
/// session to show it in, which is not an exception, so no `try`/`catch`
/// upstream can recover from it, and startup can't decide which screen to
/// show until it knows whether a token exists. Timing out and reporting "no
/// stored token" instead means the worst case is a valid session landing on
/// the login screen (actionable), not a splash screen nobody can leave.
final class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    this.accessKey = defaultAccessKey,
    this.refreshKey = defaultRefreshKey,
    Duration? readTimeout,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _readTimeout = readTimeout ?? const Duration(seconds: 5);

  static const String defaultAccessKey = 'auth_token';
  static const String defaultRefreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  final Duration _readTimeout;
  final String accessKey;
  final String refreshKey;

  Future<String?> _read(String key) =>
      _storage.read(key: key).timeout(_readTimeout, onTimeout: () => null);

  @override
  Future<String?> readAccessToken() => _read(accessKey);

  @override
  Future<String?> readRefreshToken() => _read(refreshKey);

  @override
  Future<void> saveAccessToken(String token) => _storage.write(key: accessKey, value: token);

  @override
  Future<void> saveRefreshToken(String token) => _storage.write(key: refreshKey, value: token);

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  @override
  Future<void> clearAccessToken() => _storage.delete(key: accessKey);

  @override
  Future<void> clearRefreshToken() => _storage.delete(key: refreshKey);

  @override
  Future<void> clear() async {
    await clearAccessToken();
    await clearRefreshToken();
  }
}
