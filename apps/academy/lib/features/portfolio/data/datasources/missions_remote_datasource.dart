import 'dart:convert';
import 'package:petrimonium_academy/core/constants/api_constants.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class MissionsRemoteDataSource {
  final ApiClient apiClient;

  MissionsRemoteDataSource({required this.apiClient});

  /// Triggers the backend to re-check every mission's progress against the
  /// user's real learning activity for its current period and persist any
  /// newly-completed instance.
  Future<Map<String, dynamic>> evaluate() async {
    final response = await apiClient.get(ApiConstants.missionsEndpoint);
    if (response.statusCode != 200) {
      throw Exception(
        extractErrorDetail(response, fallback: 'Failed to evaluate missions. Status Code: ${response.statusCode}'),
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
