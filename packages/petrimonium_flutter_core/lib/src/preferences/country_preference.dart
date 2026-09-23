import 'package:flutter/foundation.dart';
import '../i18n/translator_engine.dart';
import '../util/user_scoped_prefs.dart';

/// País da conta, guardado localmente e sincronizado com
/// `/api/settings/country`. Segue a forma do [TranslatorEngine] — notifier para
/// os widgets reagirem sem pacote de estado — mas o valor arranca a null de
/// propósito: null é "ainda não escolheu", e o país nunca se infere do
/// dispositivo (decisão de produto: país, moeda e idioma são escolhas
/// independentes e explícitas).
///
/// A chave é escopada por conta ([UserScopedPrefs]) pela mesma razão que o
/// progresso da Academy o é: [load] corre uma única vez no `main()` e nada a
/// volta a correr depois de um login, e o `logout()` limpa `auth_email` mas
/// deixa as preferências de propósito. Com uma chave global, um dispositivo
/// partilhado servia à segunda conta o país escolhido pela primeira — e isso
/// sobrevivia tanto à troca de sessão como ao reinício da app, até alguém abrir
/// as Definições e disparar a sincronização com o servidor.
class CountryPreference {
  CountryPreference._();

  static const String _baseKey = 'account_country';

  /// Onde o ecossistema opera nesta fase. ISO 3166-1 alpha-2.
  static const Set<String> supported = {'BR', 'PT'};

  static final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);

  static String? get current => notifier.value;

  static Future<void> load() async {
    final saved = await UserScopedPrefs.readString(_baseKey);
    if (saved != null && supported.contains(saved)) {
      notifier.value = saved;
    }
  }

  static Future<void> setCountry(String countryCode) async {
    if (!supported.contains(countryCode)) return;
    notifier.value = countryCode;
    await UserScopedPrefs.writeString(_baseKey, countryCode);
  }

  /// A classe é toda estática, por isso o [notifier] sobrevive entre testes.
  @visibleForTesting
  static void debugReset() => notifier.value = null;
}
