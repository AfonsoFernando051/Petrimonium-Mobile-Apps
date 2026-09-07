import 'dart:convert';

import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

/// Thin HTTP layer over `GET /api/investments/asset-details/{ticker}`.
/// Returns raw decoded JSON — mapping into the domain entity is the
/// repository's responsibility, matching the existing datasource/repository
/// split used throughout the app.
class AssetDetailsRemoteDataSource {
  final ApiClient apiClient;

  AssetDetailsRemoteDataSource({required this.apiClient});

  Future<Map<String, dynamic>> fetchAssetDetails(String ticker) async {
    final response = await apiClient.get('/api/investments/asset-details/$ticker');
    if (response.statusCode != 200) {
      throw Exception('Failed to load asset details for $ticker (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
