import 'missions_remote_datasource.dart';
import '../domain/mission_status.dart';

class MissionsRepository {
  final MissionsRemoteDataSource remoteDataSource;

  MissionsRepository({required this.remoteDataSource});

  Future<MissionEvaluationResult> evaluate() async {
    final raw = await remoteDataSource.evaluate();
    return MissionEvaluationResult.fromJson(raw);
  }
}
