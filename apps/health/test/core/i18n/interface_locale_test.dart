import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_health/core/profile/health_profile.dart';
import 'package:petrimonium_health/l10n/app_localizations.dart';

void main() {
  group('InterfaceLocale', () {
    test('toda entrada do enum tem localização gerada correspondente', () {
      // Impede o caso silencioso de acrescentar um idioma ao enum sem o ARB:
      // a opção apareceria nas Preferências e a interface continuaria noutra
      // língua, sem erro nenhum.
      final geradas = AppLocalizations.supportedLocales.map((locale) => locale.languageCode).toSet();
      for (final entrada in InterfaceLocale.values) {
        expect(geradas, contains(entrada.locale.languageCode), reason: '${entrada.tag} não tem localização gerada');
      }
    });

    test('parse aceita a tag de toda entrada, com _ ou -', () {
      for (final entrada in InterfaceLocale.values) {
        expect(InterfaceLocale.parse(entrada.tag), entrada);
        expect(InterfaceLocale.parse(entrada.tag.replaceAll('-', '_')), entrada);
      }
    });

    test('os quatro idiomas do design estão disponíveis', () {
      expect(InterfaceLocale.values.map((entrada) => entrada.tag).toSet(), {'pt-BR', 'pt-PT', 'en', 'es'});
    });
  });
}
