import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves a key to product copy in the language the user picked, and
/// remembers that choice across launches.
///
/// This is only the mechanism. It holds no strings of its own: an app supplies
/// a [base] catalogue (the wording every product shares) and its own
/// [overrides] (the wording that is this product's voice), and the engine
/// merges them once, overrides winning. That split is what lets two products
/// share ~1300 identical strings without either of them losing the handful it
/// deliberately words differently.
///
/// [languageNotifier] lets widgets rebuild reactively when the user switches
/// language without pulling in a state-management package, matching this
/// project's existing DI-by-static-class style.
class TranslatorEngine {
  TranslatorEngine({
    required Map<String, Map<String, String>> base,
    required Map<String, Map<String, String>> overrides,
    required this.defaultLanguage,
    required this.supportedLanguages,
    String prefsKey = 'app_language',
  }) : _prefsKey = prefsKey,
       _localizedValues = _merge(base, overrides);

  /// Language used when the user has never chosen one, and the fallback for
  /// any key a chosen language does not define.
  final String defaultLanguage;

  /// Languages the app offers. A value outside this set is ignored rather than
  /// stored, so a stale or hand-edited preference cannot strand the user in a
  /// language the app has no copy for.
  final Set<String> supportedLanguages;

  final String _prefsKey;
  final Map<String, Map<String, String>> _localizedValues;

  /// Per language, the app's own entries win over the shared ones. Languages
  /// are unioned, so a sparse overlay (`pt_PT`) stays sparse: a key it does
  /// not define is *not* filled in here, it falls back at lookup time.
  static Map<String, Map<String, String>> _merge(
    Map<String, Map<String, String>> base,
    Map<String, Map<String, String>> overrides,
  ) {
    return {
      for (final language in {...base.keys, ...overrides.keys}) language: {...?base[language], ...?overrides[language]},
    };
  }

  late final ValueNotifier<String> languageNotifier = ValueNotifier(defaultLanguage);

  String get currentLanguage => languageNotifier.value;

  /// Synchronous setter kept for tests and simple in-memory switches.
  /// Prefer [setLanguage] in the app so the preference is persisted.
  set currentLanguage(String language) {
    languageNotifier.value = language;
  }

  /// Loads the persisted language preference. Call once during app startup,
  /// before the first screen is built.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supportedLanguages.contains(saved)) {
      languageNotifier.value = saved;
    }
  }

  /// Updates the current language and persists it locally.
  /// Does not call the backend — callers that need the preference synced
  /// server-side (e.g. the Settings screen) should do that separately.
  Future<void> setLanguage(String language) async {
    if (!supportedLanguages.contains(language)) return;
    languageNotifier.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language);
  }

  /// [params] fills `{token}` placeholders in the translated string (e.g.
  /// `{petName}`) — used for copy that embeds the user's chosen pet name,
  /// which can't be baked into the static translation map.
  String translate(String key, {Map<String, String>? params}) {
    var value = _localizedValues[currentLanguage]?[key] ?? _localizedValues[defaultLanguage]?[key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }

  /// Test-only escape hatch onto the merged catalogue, so `translator_test.dart`
  /// can assert the language blocks stay key-parallel (a missing es/en key
  /// otherwise silently falls back to pt, with nothing surfacing the gap — see
  /// `docs/DECISIONS.md` DECISION-037). Not used by app code.
  Map<String, Map<String, String>> get debugLocalizedValues => _localizedValues;
}
