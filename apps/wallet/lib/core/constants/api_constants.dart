import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class ApiConstants {
  // Base URL and the release-build guard now live in PetrimoniumEnvironment
  // (petrimonium_flutter_core) — all three products resolve the same
  // API_BASE_URL define against the same localhost default, so keeping two
  // copies of this logic in sync was pure duplication risk. ApiConstants
  // stays as the public surface the rest of Wallet already imports; it just
  // delegates instead of reimplementing.
  static const String baseUrl = PetrimoniumEnvironment.baseUrl;

  // The Web OAuth 2.0 Client ID from Google Cloud Console, passed to
  // GoogleSignIn as serverClientId so the ID token it returns is valid for
  // this backend's `google.oauth.client-ids` audience check. Empty by
  // default — Google Sign-In is not usable until this is supplied, e.g.:
  //   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// A release build that never received --dart-define=API_BASE_URL=... would otherwise
  /// silently ship pointed at a developer's own machine — fail loudly and immediately
  /// instead, rather than have every request quietly fail (or worse, quietly succeed against
  /// the wrong backend) in front of a real user.
  static void assertConfiguredForRelease() => PetrimoniumEnvironment.assertConfiguredForRelease();

  // Identifies this app to the backend at login so the issued JWT carries the
  // matching `app_context` claim — required as of backend commit 7b51782,
  // which gates /api/investments/** behind APP_CONTEXT_WALLET. Fixed per-app
  // value, not a build flag: this binary is only ever the Wallet client.
  static const String appContext = 'wallet';

  static const String loginEndpoint = '/auth/login';
  static const String googleLoginEndpoint = '/auth/google';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';

  static const String onboardingQuestionsEndpoint = '/api/onboarding/questions';
  static const String onboardingSubmitEndpoint = '/api/onboarding/submit';
  static const String onboardingStatusEndpoint = '/api/onboarding/status';

  static const String settingsLanguageEndpoint = '/api/settings/language';
  static const String settingsCountryEndpoint = '/api/settings/country';
  static const String settingsAccountEndpoint = '/api/settings/account';

  static const String mentorChatEndpoint = '/api/mentor/chat';
  static String mentorSuggestionsEndpoint(String language) => '/api/mentor/suggestions?language=$language';
  static const String mentorConversationsEndpoint = '/api/mentor/conversations';
  static String mentorConversationEndpoint(int id) => '/api/mentor/conversations/$id';

  static String learningLessonCompleteEndpoint(String lessonId) => '/api/v1/learning/lessons/$lessonId/complete';
  static const String learningProgressEndpoint = '/api/v1/learning/progress';

  static String labSimulatorCompleteEndpoint(String simulatorId) => '/api/v1/lab/simulators/$simulatorId/complete';
  static const String labSimulatorsProgressEndpoint = '/api/v1/lab/simulators/progress';
  static const String academyCatalogEndpoint = '/api/v1/academy/catalog';

  static const String gamificationSummaryEndpoint = '/api/v1/gamification/summary';
  static const String achievementsEndpoint = '/api/v1/achievements';
  static const String missionsEndpoint = '/api/v1/missions';
}
