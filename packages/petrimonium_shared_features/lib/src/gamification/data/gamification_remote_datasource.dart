import 'dart:convert';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class GamificationRemoteDataSource {
  /// The gamification summary route. It lives here rather than in each app's
  /// ApiConstants because it is the shared feature's own contract with the
  /// backend - both apps already pointed at exactly this path, and a single
  /// definition is what stops them from drifting apart.
  static const String summaryEndpoint = '/api/v1/gamification/summary';

  final ApiClient apiClient;

  GamificationRemoteDataSource({required this.apiClient});

  Future<Map<String, dynamic>> fetchSummary() async {
    final response = await apiClient.get(summaryEndpoint);
    if (response.statusCode != 200) {
      throw Exception(
        extractErrorDetail(
          response,
          fallback: 'Failed to load gamification summary. Status Code: ${response.statusCode}',
        ),
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
