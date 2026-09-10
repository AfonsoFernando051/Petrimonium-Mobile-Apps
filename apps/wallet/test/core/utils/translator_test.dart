import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  group('Translator', () {
    test('translates key to Portuguese by default', () {
      expect(Translator.translate(AppStrings.welcomeBack), 'Bem-vindo de volta');
    });

    test('translates key to English when language changes', () {
      Translator.currentLanguage = 'en';
      expect(Translator.translate(AppStrings.welcomeBack), 'Welcome back');
    });

    test('translates key to Spanish when language changes', () {
      Translator.currentLanguage = 'es';
      expect(Translator.translate(AppStrings.welcomeBack), 'Bienvenido de nuevo');
    });

    test('falls back to default language if language is unsupported', () {
      Translator.currentLanguage = 'fr';
      expect(Translator.translate(AppStrings.welcomeBack), 'Bem-vindo de volta');
    });

    test('returns key itself if translation for key is missing', () {
      expect(Translator.translate('unknownKey'), 'unknownKey');
    });
  });

  // A missing en/es key silently falls back to pt via `translate()` — no
  // exception, no visible sign anything is wrong. These guard against that:
  // a language block drifting out of parity is caught here, not by a user
  // spotting Portuguese text in the English app.
  group('Translator — language parity', () {
    test('pt_PT só define chaves que pt também define', () {
      final values = Translator.debugLocalizedValues;
      final ptKeys = values['pt']!.keys.toSet();
      final ptPtKeys = values['pt_PT']!.keys.toSet();
      // pt_PT é um overlay esparso: pode definir menos que pt, nunca outra
      // coisa. Uma chave aqui que pt não conheça é erro de digitação.
      expect(ptPtKeys.difference(ptKeys), isEmpty, reason: 'pt_PT define chaves que pt desconhece');
      expect(ptPtKeys, isNotEmpty);
    });

    test('en defines exactly the same key set as pt', () {
      final values = Translator.debugLocalizedValues;
      final ptKeys = values['pt']!.keys.toSet();
      final enKeys = values['en']!.keys.toSet();
      expect(enKeys.difference(ptKeys), isEmpty, reason: 'en has keys pt does not define');
      expect(ptKeys.difference(enKeys), isEmpty, reason: 'en is missing keys pt defines');
    });

    test('es defines exactly the same key set as pt', () {
      final values = Translator.debugLocalizedValues;
      final ptKeys = values['pt']!.keys.toSet();
      final esKeys = values['es']!.keys.toSet();
      expect(esKeys.difference(ptKeys), isEmpty, reason: 'es has keys pt does not define');
      expect(ptKeys.difference(esKeys), isEmpty, reason: 'es is missing keys pt defines');
    });

    test('no translation value is left as an untranslated copy of its key', () {
      final offenders = <String>[];
      for (final entry in Translator.debugLocalizedValues.entries) {
        for (final kv in entry.value.entries) {
          if (kv.value == kv.key) offenders.add('${entry.key}.${kv.key}');
        }
      }
      expect(offenders, isEmpty, reason: 'these entries were never actually translated: $offenders');
    });
  });

  // The shared catalogue only pays off while the two halves stay disjoint.
  // Nothing stops someone pasting a string into this app's own map that the
  // shared one already words identically — at which point the duplication is
  // quietly back, and a later fix to the shared copy stops reaching this app.
  group('Translator — shared/product split', () {
    test('the product catalogue never repeats a value sharedCopy already has', () {
      final offenders = <String>[];
      Translator.debugProductCopy.forEach((language, entries) {
        entries.forEach((key, value) {
          if (sharedCopy[language]?[key] == value) offenders.add('$language.$key');
        });
      });
      expect(offenders, isEmpty, reason: 'these belong in sharedCopy, not in this app: $offenders');
    });

    test('every product override for a shared key is a deliberate wording change', () {
      // Overriding a key the ecosystem shares is allowed — that is this
      // product's voice — but it must actually say something different.
      final shadowed = Translator.debugProductCopy['pt']!.keys.where(sharedCopy['pt']!.containsKey);
      for (final key in shadowed) {
        expect(Translator.debugProductCopy['pt']![key], isNot(sharedCopy['pt']![key]), reason: key);
      }
    });
  });
}
