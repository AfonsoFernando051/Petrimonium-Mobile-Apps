import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// País da conta, guardado localmente e sincronizado com
/// `/api/settings/country`. Segue a forma do [Translator] — notifier para os
/// widgets reagirem sem pacote de estado — mas o valor arranca a null de
/// propósito: null é "ainda não escolheu", e o país nunca se infere do
/// dispositivo (decisão de produto: país, moeda e idioma são escolhas
/// independentes e explícitas).
class CountryPreference {
  CountryPreference._();

  static const String _prefsKey = 'account_country';

  /// Onde o ecossistema opera nesta fase. ISO 3166-1 alpha-2.
  static const Set<String> supported = {'BR', 'PT'};

  static final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);

  static String? get current => notifier.value;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supported.contains(saved)) {
      notifier.value = saved;
    }
  }

  static Future<void> setCountry(String countryCode) async {
    if (!supported.contains(countryCode)) return;
    notifier.value = countryCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, countryCode);
  }
}
