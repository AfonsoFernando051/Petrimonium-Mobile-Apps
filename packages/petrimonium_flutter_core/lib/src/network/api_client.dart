import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/petrimonium_environment.dart';
import 'token_store.dart';

/// Every authenticated request goes through here, which is what makes
/// centralized 401 handling possible: a 401 triggers exactly one refresh
/// attempt (single-flight — concurrent 401s share the same in-flight
/// refresh rather than each firing their own) and, on success, retries the
/// original request once with the new access token. If refresh fails (no
/// refresh token stored, or the backend rejects it as invalid/expired/
/// revoked), both tokens are cleared and [onSessionExpired] is invoked so
/// the app's root listener can send the user back to the login screen — no
/// individual screen has to know any of this happened.
///
/// It deliberately calls a callback rather than emitting onto an event bus.
/// Each product owns its own sealed `AppEvent` hierarchy (a sealed type
/// cannot be extended from another library), so a client living in a shared
/// package cannot emit one. The app supplies the bridge at construction:
/// `onSessionExpired: () => AppEventBus.instance.emit(const SessionExpiredEvent())`.
class ApiClient {
  final http.Client _client;
  final TokenStore _tokenStore;

  /// Without a bound, a stalled connection (dead wifi, backend hung) leaves the caller
  /// awaiting forever — every request gets a `TimeoutException` instead past this point.
  static const Duration _requestTimeout = Duration(seconds: 15);

  /// [client]/[secureStorage] are injectable so tests can substitute mocks —
  /// production code relies on the defaults. [tokenStore] replaces the whole
  /// token storage strategy at once (a product with its own storage keys, or
  /// a test fake); it takes precedence over [secureStorage] when both are
  /// given.
  ///
  /// [baseUrl] and [refreshTokenEndpoint] default to
  /// [PetrimoniumEnvironment]; they are parameters only so tests can point a
  /// client at a fake host without touching global state.
  ///
  /// [sessionCheckTimeout] bounds [hasSession] alone — see its doc comment.
  ApiClient({
    http.Client? client,
    FlutterSecureStorage? secureStorage,
    TokenStore? tokenStore,
    String? baseUrl,
    String? refreshTokenEndpoint,
    void Function()? onSessionExpired,
    Duration? sessionCheckTimeout,
  }) : _client = client ?? http.Client(),
       _tokenStore = tokenStore ?? SecureTokenStore(storage: secureStorage),
       _baseUrl = baseUrl ?? PetrimoniumEnvironment.baseUrl,
       _refreshTokenEndpoint = refreshTokenEndpoint ?? PetrimoniumEnvironment.refreshTokenEndpoint,
       _onSessionExpired = onSessionExpired,
       _sessionCheckTimeout = sessionCheckTimeout ?? const Duration(seconds: 5);

  final String _baseUrl;
  final String _refreshTokenEndpoint;
  final Duration _sessionCheckTimeout;

  /// Invoked exactly once per definitive session loss, after both tokens have
  /// already been cleared. Null is a valid configuration (a client used for
  /// unauthenticated calls has nothing to report).
  final void Function()? _onSessionExpired;

  /// Key under which the bearer token is stored by the default [TokenStore].
  static const String authTokenKey = SecureTokenStore.defaultAccessKey;

  /// Same storage/security reasoning as [authTokenKey].
  static const String refreshTokenKey = SecureTokenStore.defaultRefreshKey;

  // Single-flight refresh lock: every 401 that arrives while a refresh is
  // already in progress awaits this same future instead of starting its
  // own — otherwise N concurrent requests failing together would fire N
  // simultaneous refresh calls, each trying to rotate the same token out
  // from under the others.
  Future<bool>? _refreshInFlight;

  /// Direct access to the token store, for repositories that need to persist
  /// or read a token pair from a call this client didn't make itself — e.g.
  /// saving the pair returned by a login hit through [unauthenticatedPost].
  TokenStore get tokenStore => _tokenStore;

  Future<String?> readToken() => _tokenStore.readAccessToken();

  Future<void> saveToken(String token) => _tokenStore.saveAccessToken(token);

  Future<void> clearToken() => _tokenStore.clearAccessToken();

  Future<String?> readRefreshToken() => _tokenStore.readRefreshToken();

  Future<void> saveRefreshToken(String token) => _tokenStore.saveRefreshToken(token);

  Future<void> clearRefreshToken() => _tokenStore.clearRefreshToken();

  /// Saves both halves of a login/refresh response's token pair together —
  /// the two are always issued and consumed as a pair, never independently.
  Future<void> saveTokens({required String accessToken, required String refreshToken}) =>
      _tokenStore.saveTokens(accessToken, refreshToken);

  Future<void> clearTokens() => _tokenStore.clear();

  /// Whether a session looks usable, i.e. an access token is stored. Does
  /// not validate the token against the backend — just answers "is there a
  /// session worth trying", which is what a splash screen needs before it
  /// can decide whether to route to login or straight into the app.
  ///
  /// Bounded by [_sessionCheckTimeout]: this is the one caller that can't
  /// afford to hang on a platform keyring that never answers (e.g. a locked
  /// GNOME keyring raising an unlock prompt with no session to show it in —
  /// not an exception, so no `try`/`catch` upstream can recover from it). A
  /// timed-out read reads as "no session", landing on the login screen
  /// (actionable) instead of a splash screen nobody can leave. Every other
  /// token read stays unbounded — see [SecureTokenStore]'s doc comment for
  /// why the same guard there would be worse for those callers.
  Future<bool> hasSession() async {
    try {
      final token = await readToken().timeout(_sessionCheckTimeout);
      return token?.isNotEmpty ?? false;
    } on TimeoutException {
      return false;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await readToken();

    return {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  }

  /// [timeout] overrides [_requestTimeout] for callers that know their
  /// request is expected to take longer than a normal API call — e.g. the
  /// Mentor chat endpoint, which waits on an LLM reply rather than a
  /// straightforward database read.
  Future<http.Response> post(String endpoint, dynamic body, {Duration? timeout}) {
    return _sendWithAuth(
      (headers) => _client
          .post(Uri.parse('$_baseUrl$endpoint'), headers: headers, body: jsonEncode(body))
          .timeout(timeout ?? _requestTimeout),
    );
  }

  Future<http.Response> get(String endpoint) {
    return _sendWithAuth(
      (headers) => _client.get(Uri.parse('$_baseUrl$endpoint'), headers: headers).timeout(_requestTimeout),
    );
  }

  Future<http.Response> put(String endpoint, dynamic body) {
    return _sendWithAuth(
      (headers) => _client
          .put(Uri.parse('$_baseUrl$endpoint'), headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout),
    );
  }

  Future<http.Response> patch(String endpoint, dynamic body) {
    return _sendWithAuth(
      (headers) => _client
          .patch(Uri.parse('$_baseUrl$endpoint'), headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout),
    );
  }

  Future<http.Response> delete(String endpoint) {
    return _sendWithAuth(
      (headers) => _client.delete(Uri.parse('$_baseUrl$endpoint'), headers: headers).timeout(_requestTimeout),
    );
  }

  /// Sends a POST with no bearer token and no 401-refresh handling — for
  /// endpoints that authenticate a session rather than use one, e.g. login,
  /// register or a Google-token exchange. The caller reads the response
  /// itself and persists the returned pair via [tokenStore].
  Future<http.Response> unauthenticatedPost(String endpoint, dynamic body, {Duration? timeout}) {
    return _client
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout ?? _requestTimeout);
  }

  /// Sends [send] with fresh auth headers; on a 401, attempts exactly one
  /// refresh-and-retry. [isRetry] caps that to a single attempt — a 401 on
  /// the retried request itself (refresh "succeeded" but the new token is
  /// somehow still rejected, or some other 401 cause entirely) is returned
  /// as-is rather than looping.
  ///
  /// Retrying after a successful refresh is safe for every HTTP method here
  /// (not just GET): the backend's JWT filter rejects an unauthenticated
  /// request before it ever reaches a controller/use case
  /// (`JwtAuthenticationFilter`, ordered ahead of every route), so a 401
  /// response is a guarantee that no business logic — no mutation — ran for
  /// that request. There is nothing to double-apply by retrying it.
  Future<http.Response> _sendWithAuth(
    Future<http.Response> Function(Map<String, String> headers) send, {
    bool isRetry = false,
  }) async {
    final headers = await _getHeaders();
    final response = await send(headers);

    if (response.statusCode != 401 || isRetry) {
      return response;
    }

    final refreshed = await _refreshAccessToken();
    if (!refreshed) {
      return response;
    }

    return _sendWithAuth(send, isRetry: true);
  }

  Future<bool> _refreshAccessToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _handleSessionExpired();
      return false;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$_refreshTokenEndpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        await _handleSessionExpired();
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;
      if (newAccessToken == null || newRefreshToken == null) {
        await _handleSessionExpired();
        return false;
      }

      await saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
      return true;
    } catch (_) {
      // A network-level failure (timeout, no connectivity) refreshing the
      // token is not the same claim as "this session is invalid" — the
      // original request already failed with a real 401 from the server,
      // so surfacing that as-is (rather than force-logging-out on what
      // might just be a flaky connection) is the safer read of what
      // actually happened.
      return false;
    }
  }

  Future<void> _handleSessionExpired() async {
    await clearTokens();
    _onSessionExpired?.call();
  }
}
