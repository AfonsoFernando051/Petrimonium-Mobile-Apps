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
/// Reads here are unbounded on purpose: a keyring that never answers is
/// [ApiClient.hasSession]'s problem to guard against (it bounds the wait
/// there, for the one caller — startup routing — that can't afford to hang),
/// not every ordinary read. Applying a timeout uniformly here would mean a
/// keyring that's merely slow to unlock mid-session gets read as "no token"
/// on a routine API call, forcing a refresh that also times out and logs an
/// otherwise-valid session out — worse than the request just waiting.
final class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    this.accessKey = defaultAccessKey,
    this.refreshKey = defaultRefreshKey,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const String defaultAccessKey = 'auth_token';
  static const String defaultRefreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  final String accessKey;
  final String refreshKey;

  @override
  Future<String?> readAccessToken() => _storage.read(key: accessKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: refreshKey);

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
