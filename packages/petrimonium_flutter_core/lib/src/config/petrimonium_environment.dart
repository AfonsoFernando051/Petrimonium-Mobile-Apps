import 'package:flutter/foundation.dart';

/// Where the backend lives, and the guard that stops a release build from
/// shipping pointed at a developer's laptop.
///
/// This is genuinely shared: all three products talk to the same Petrimonium
/// backend and already resolved the base URL exactly this way, from the same
/// `API_BASE_URL` define with the same default. It is *environment* config,
/// not product config - which is why it can live here while each app keeps
/// its own endpoint list and its own `appContext`.
abstract final class PetrimoniumEnvironment {
  /// Overridable per build without editing source, e.g.:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081   (Android emulator)
  ///   flutter build apk --dart-define=API_BASE_URL=https://api.example.com
  /// Defaults to http://localhost:8081, which works for iOS Simulator/Web but
  /// NOT the Android emulator (use 10.0.2.2 there).
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: devDefaultBaseUrl);

  static const String devDefaultBaseUrl = 'http://localhost:8081';

  /// The token-refresh route. Same on every product because it is the same
  /// backend and the same identity context.
  static const String refreshTokenEndpoint = '/auth/refresh';

  /// A release build that never received --dart-define=API_BASE_URL=... would
  /// otherwise silently ship pointed at a developer's own machine - fail
  /// loudly and immediately instead, rather than have every request quietly
  /// fail (or worse, quietly succeed against the wrong backend) in front of a
  /// real user.
  static void assertConfiguredForRelease() {
    if (kReleaseMode && baseUrl == devDefaultBaseUrl) {
      throw StateError(
        'API_BASE_URL must be provided for release builds '
        '(--dart-define=API_BASE_URL=https://...).',
      );
    }
  }
}
