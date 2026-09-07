import 'package:petrimonium_academy/features/portfolio/data/datasources/achievements_remote_datasource.dart';
import 'package:petrimonium_academy/features/portfolio/domain/entities/achievement_evaluation_result.dart';

class AchievementsRepository {
  final AchievementsRemoteDataSource remoteDataSource;

  AchievementsRepository({required this.remoteDataSource});

  Future<AchievementEvaluationResult> evaluate() async {
    final raw = await remoteDataSource.evaluate();
    return AchievementEvaluationResult.fromJson(raw);
  }
}
