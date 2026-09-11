import 'package:petrimonium_wallet/features/investment/data/datasources/investment_remote_datasource.dart';
import 'package:petrimonium_wallet/features/investment/data/models/asset_registration_model.dart';

class InvestmentRepository {
  final InvestmentRemoteDataSource remoteDataSource;

  InvestmentRepository({required this.remoteDataSource});

  Future<void> configureInvestments(List<AssetRegistrationModel> investments, {bool confirmReplace = false}) async {
    return remoteDataSource.configureInvestments(investments, confirmReplace: confirmReplace);
  }

  Future<void> addInvestment(AssetRegistrationModel asset) async {
    return remoteDataSource.addInvestment(asset);
  }

  Future<void> updateInvestment(int id, AssetRegistrationModel asset) async {
    return remoteDataSource.updateInvestment(id, asset);
  }

  Future<void> deleteInvestment(int id) async {
    return remoteDataSource.deleteInvestment(id);
  }

  Future<Map<String, dynamic>?> fetchQuote(String ticker) async {
    return remoteDataSource.fetchQuote(ticker);
  }

  Future<Map<String, dynamic>?> fetchQuoteAtDate(String ticker, String date) async {
    return remoteDataSource.fetchQuoteAtDate(ticker, date);
  }

  Future<List<Map<String, dynamic>>> searchQuotes(String query) async {
    return remoteDataSource.searchQuotes(query);
  }
}
