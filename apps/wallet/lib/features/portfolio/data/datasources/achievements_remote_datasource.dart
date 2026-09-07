import 'dart:convert';
import 'package:petrimonium/core/constants/api_constants.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class AchievementsRemoteDataSource {
  final ApiClient apiClient;

  AchievementsRemoteDataSource({required this.apiClient});

  /// Triggers the backend to re-check every achievement condition against
  /// the user's real portfolio and persist any newly-qualifying unlock.
  Future<Map<String, dynamic>> evaluate() async {
    final response = await apiClient.get(ApiConstants.achievementsEndpoint);
    if (response.statusCode != 200) {
      throw Exception(
        extractErrorDetail(response, fallback: 'Failed to evaluate achievements. Status Code: ${response.statusCode}'),
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
