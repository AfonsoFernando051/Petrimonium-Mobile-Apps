import '../domain/allocation_slice.dart';
import '../domain/dividend_event.dart';
import '../domain/history_point.dart';
import '../domain/history_range.dart';
import '../domain/holding.dart';
import '../domain/investment_lot.dart';
import '../domain/portfolio_summary.dart';
import 'portfolio_remote_datasource.dart';

class PortfolioRepository {
  final PortfolioRemoteDataSource remoteDataSource;

  PortfolioRepository({required this.remoteDataSource});

  Future<List<Holding>> fetchHoldings() async {
    final raw = await remoteDataSource.fetchHoldings();
    final lots = raw.map(InvestmentLot.fromJson).toList();
    return Holding.fromLots(lots);
  }

  Future<PortfolioSummary> fetchSummary() async {
    final raw = await remoteDataSource.fetchSummary();
    return PortfolioSummary.fromJson(raw);
  }

  Future<List<AllocationSlice>> fetchAllocation() async {
    final raw = await remoteDataSource.fetchAllocation();
    return raw.map(AllocationSlice.fromJson).toList();
  }

  Future<List<HistoryPoint>> fetchHistory(HistoryRange range) async {
    final raw = await remoteDataSource.fetchHistory(range.apiValue);
    return raw.map(HistoryPoint.fromJson).toList();
  }

  Future<DividendRadar> fetchDividendRadar() async {
    final raw = await remoteDataSource.fetchDividends();
    return DividendRadar.fromJson(raw);
  }
}
