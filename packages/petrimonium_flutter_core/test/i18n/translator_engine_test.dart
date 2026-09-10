import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The engine's whole reason to exist is the base/override merge: two products
/// share one catalogue without either losing the strings it words its own way.
/// These pin that merge, and the fallback chain that makes a sparse overlay
/// language (`pt_PT`) safe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const base = {
    'pt': {'greeting': 'Olá', 'shared': 'Comum', 'params': 'Olá, {name}! Até já, {name}.'},
    'pt_PT': {'greeting': 'Olá (PT)'},
    'en': {'greeting': 'Hello', 'shared': 'Common'},
  };
  const overrides = {
    'pt': {'greeting': 'Bom dia', 'own': 'Só deste produto'},
    'es': {'greeting': 'Hola'},
  };

  TranslatorEngine build() => TranslatorEngine(
    base: base,
    overrides: overrides,
    defaultLanguage: 'pt',
    supportedLanguages: const {'pt', 'pt_PT', 'en', 'es'},
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('merge', () {
    test('the product override wins over the shared value for the same key', () {
      expect(build().translate('greeting'), 'Bom dia');
    });

    test('a key the product does not override still resolves from the shared catalogue', () {
      expect(build().translate('shared'), 'Comum');
    });

    test('a key only the product defines resolves', () {
      expect(build().translate('own'), 'Só deste produto');
    });

    test('languages are unioned, so a language only the product has exists', () {
      final engine = build()..currentLanguage = 'es';
      expect(engine.translate('greeting'), 'Hola');
    });

    test('a sparse overlay language is not filled in by the merge', () {
      // pt_PT defines `greeting` only. If the merge had padded it out of `pt`,
      // every future pt/pt_PT wording split would silently stop working.
      expect(build().debugLocalizedValues['pt_PT']!.keys, ['greeting']);
    });
  });

  group('lookup', () {
    test('an overlay language falls back to the default language per key', () {
      final engine = build()..currentLanguage = 'pt_PT';
      expect(engine.translate('greeting'), 'Olá (PT)');
      expect(engine.translate('shared'), 'Comum');
    });

    test('an unsupported current language falls back to the default language', () {
      final engine = build()..currentLanguage = 'fr';
      expect(engine.translate('greeting'), 'Bom dia');
    });

    test('an unknown key returns the key itself rather than throwing', () {
      expect(build().translate('nopeNotAKey'), 'nopeNotAKey');
    });

    test('params replace every occurrence of the placeholder', () {
      expect(build().translate('params', params: {'name': 'Nino'}), 'Olá, Nino! Até já, Nino.');
    });

    test('a placeholder with no matching param is left untouched', () {
      expect(build().translate('params', params: {'other': 'x'}), 'Olá, {name}! Até já, {name}.');
    });
  });

  group('persistence', () {
    test('setLanguage stores a supported language', () async {
      final engine = build();
      await engine.setLanguage('en');
      expect(engine.currentLanguage, 'en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'en');
    });

    test('setLanguage ignores an unsupported language and stores nothing', () async {
      final engine = build();
      await engine.setLanguage('de');
      expect(engine.currentLanguage, 'pt');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), isNull);
    });

    test('load restores a persisted language', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      final engine = build();
      await engine.load();
      expect(engine.currentLanguage, 'en');
    });

    test('load ignores a persisted language the app no longer supports', () async {
      // A hand-edited or stale preference must not strand the user in a
      // language this build has no copy for.
      SharedPreferences.setMockInitialValues({'app_language': 'de'});
      final engine = build();
      await engine.load();
      expect(engine.currentLanguage, 'pt');
    });

    test('languageNotifier fires so widgets rebuild on a language switch', () {
      final engine = build();
      final seen = <String>[];
      engine.languageNotifier.addListener(() => seen.add(engine.currentLanguage));
      engine.currentLanguage = 'en';
      expect(seen, ['en']);
    });
  });
}
