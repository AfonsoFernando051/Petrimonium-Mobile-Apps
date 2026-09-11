import 'package:petrimonium_academy/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

class OnboardingRepository {
  final OnboardingRemoteDataSource remoteDataSource;

  OnboardingRepository({required this.remoteDataSource});

  Future<OnboardingStatusModel> getStatus() => remoteDataSource.getStatus();

  Future<String> submitAssessment({
    required String goal,
    required String investmentHorizon,
    required String experienceLevel,
  }) => remoteDataSource.submitAssessment(
    goal: goal,
    investmentHorizon: investmentHorizon,
    experienceLevel: experienceLevel,
  );
}
