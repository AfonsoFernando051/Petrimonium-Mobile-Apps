import 'gamification_remote_datasource.dart';
import '../domain/gamification_summary.dart';

class GamificationRepository {
  final GamificationRemoteDataSource remoteDataSource;

  GamificationRepository({required this.remoteDataSource});

  Future<GamificationSummary> fetchSummary() async {
    final raw = await remoteDataSource.fetchSummary();
    return GamificationSummary.fromJson(raw);
  }
}
