import 'package:flutter/foundation.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

class SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepository({required this.remoteDataSource});

  Future<String> getLanguage() => remoteDataSource.getLanguage();

  /// Persists the language preference server-side. Failures are swallowed —
  /// the local preference (already saved via Translator.setLanguage) remains
  /// the source of truth for the current session, so a network hiccup
  /// shouldn't block the user from using the app in their chosen language.
  Future<void> syncLanguage(String language) async {
    try {
      await remoteDataSource.updateLanguage(language);
    } catch (e) {
      debugPrint('WARN: failed to sync language preference with backend: $e');
    }
  }

  Future<String?> getCountry() => remoteDataSource.getCountry();

  /// Mesmo contrato do idioma: a preferência local já foi guardada e
  /// continua a valer para a sessão, por isso uma falha de rede não
  /// bloqueia o utilizador.
  Future<void> syncCountry(String countryCode) async {
    try {
      await remoteDataSource.updateCountry(countryCode);
    } catch (e) {
      debugPrint('WARN: failed to sync country preference with backend: $e');
    }
  }

  /// Ao contrário das preferências, uma falha aqui NÃO é engolida: se a
  /// conta não foi apagada, o utilizador tem de saber.
  Future<void> deleteAccount() => remoteDataSource.deleteAccount();
}
