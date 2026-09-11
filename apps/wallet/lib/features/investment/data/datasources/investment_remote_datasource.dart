import 'dart:convert';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_wallet/features/investment/data/models/asset_registration_model.dart';

class InvestmentRemoteDataSource {
  final ApiClient apiClient;

  InvestmentRemoteDataSource({required this.apiClient});

  /// Replaces the caller's whole portfolio with [investments].
  ///
  /// [confirmReplace] maps to the backend's `confirmReplace` query parameter:
  /// with it `false` (the default) the server refuses a submission that would
  /// wipe out existing holdings, so a caller that hasn't shown the user their
  /// current portfolio can't silently destroy it.
  Future<void> configureInvestments(List<AssetRegistrationModel> investments, {bool confirmReplace = false}) async {
    final response = await apiClient.post(
      '/api/investments/configure?confirmReplace=$confirmReplace',
      investments.map((e) => e.toJson()).toList(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        extractErrorDetail(response, fallback: 'Failed to configure investments. Status Code: ${response.statusCode}'),
      );
    }
  }

  /// Appends [asset] as a new lot — never touches any other lot. Unlike
  /// [configureInvestments], the response body is ignored: callers refetch the
  /// priced view via `GET /api/investments` after a successful add.
  Future<void> addInvestment(AssetRegistrationModel asset) async {
    final response = await apiClient.post('/api/investments', asset.toJson());

    if (response.statusCode != 201) {
      throw Exception(
        extractErrorDetail(response, fallback: 'Failed to add investment. Status Code: ${response.statusCode}'),
      );
    }
  }

  /// Edits [id] in place — never touches any other lot.
  Future<void> updateInvestment(int id, AssetRegistrationModel asset) async {
    final response = await apiClient.put('/api/investments/$id', asset.toJson());

    if (response.statusCode != 200) {
      throw Exception(
        extractErrorDetail(response, fallback: 'Failed to update investment. Status Code: ${response.statusCode}'),
      );
    }
  }

  /// Removes [id] — never touches any other lot.
  Future<void> deleteInvestment(int id) async {
    final response = await apiClient.delete('/api/investments/$id');

    if (response.statusCode != 204) {
      throw Exception(
        extractErrorDetail(response, fallback: 'Failed to delete investment. Status Code: ${response.statusCode}'),
      );
    }
  }

  Future<Map<String, dynamic>?> fetchQuote(String ticker) async {
    try {
      final response = await apiClient.get('/api/investments/quote/$ticker');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Return null on failure
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchQuoteAtDate(String ticker, String date) async {
    try {
      final response = await apiClient.get('/api/investments/quote/$ticker/at-date?date=$date');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Return null on failure
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchQuotes(String query) async {
    try {
      final response = await apiClient.get('/api/investments/search?query=$query');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // return empty array on failure
    }
    return [];
  }
}
