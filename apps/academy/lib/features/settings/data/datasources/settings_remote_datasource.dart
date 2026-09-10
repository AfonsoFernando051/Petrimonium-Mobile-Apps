import 'dart:convert';

import 'package:petrimonium_academy/core/constants/api_constants.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class SettingsRemoteDataSource {
  final ApiClient apiClient;

  SettingsRemoteDataSource({required this.apiClient});

  Future<String> getLanguage() async {
    final response = await apiClient.get(ApiConstants.settingsLanguageEndpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['language'] as String;
    }
    throw Exception('Failed to load language preference. Status code: ${response.statusCode}');
  }

  Future<String> updateLanguage(String language) async {
    final response = await apiClient.put(ApiConstants.settingsLanguageEndpoint, {'language': language});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['language'] as String;
    }
    throw Exception('Failed to update language preference. Status code: ${response.statusCode}');
  }

  /// Devolve null quando a conta ainda não escolheu país — o backend
  /// guarda country_code nulo até à primeira escolha, de propósito.
  Future<String?> getCountry() async {
    final response = await apiClient.get(ApiConstants.settingsCountryEndpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['countryCode'] as String?;
    }
    throw Exception('Failed to load country preference. Status code: ${response.statusCode}');
  }

  Future<String> updateCountry(String countryCode) async {
    final response = await apiClient.put(ApiConstants.settingsCountryEndpoint, {'countryCode': countryCode});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['countryCode'] as String;
    }
    throw Exception('Failed to update country preference. Status code: ${response.statusCode}');
  }

  /// Apaga a conta e todos os dados dela. Irreversível.
  Future<void> deleteAccount() async {
    final response = await apiClient.delete(ApiConstants.settingsAccountEndpoint);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete account. Status code: ${response.statusCode}');
    }
  }
}
