import 'dart:convert';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class AchievementsRemoteDataSource {
  /// The achievement-evaluation route. It lives here rather than in each app's
  /// ApiConstants because it is the shared feature's own contract with the
  /// backend — both apps already pointed at exactly this path, and a single
  /// definition is what stops them from drifting apart.
  static const String achievementsEndpoint = '/api/v1/achievements';

  final ApiClient apiClient;

  AchievementsRemoteDataSource({required this.apiClient});

  /// Triggers the backend to re-check every achievement condition against
  /// the user's real portfolio and persist any newly-qualifying unlock.
  Future<Map<String, dynamic>> evaluate() async {
    final response = await apiClient.get(achievementsEndpoint);
    if (response.statusCode != 200) {
      throw Exception(
        extractErrorDetail(response, fallback: 'Failed to evaluate achievements. Status Code: ${response.statusCode}'),
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
