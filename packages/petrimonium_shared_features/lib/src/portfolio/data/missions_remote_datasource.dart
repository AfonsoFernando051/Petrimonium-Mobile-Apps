import 'dart:convert';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class MissionsRemoteDataSource {
  /// The missions route. It lives here rather than in each app's ApiConstants
  /// because it is the shared feature's own contract with the backend — both
  /// apps already pointed at exactly this path, and a single definition is
  /// what stops them from drifting apart.
  static const String missionsEndpoint = '/api/v1/missions';

  final ApiClient apiClient;

  MissionsRemoteDataSource({required this.apiClient});

  /// Triggers the backend to re-check every mission's progress against the
  /// user's real learning activity for its current period and persist any
  /// newly-completed instance.
  Future<Map<String, dynamic>> evaluate() async {
    final response = await apiClient.get(missionsEndpoint);
    if (response.statusCode != 200) {
      throw Exception(
        extractErrorDetail(response, fallback: 'Failed to evaluate missions. Status Code: ${response.statusCode}'),
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
