import 'package:petrimonium_wallet/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

class OnboardingRepository {
  final OnboardingRemoteDataSource remoteDataSource;

  OnboardingRepository({required this.remoteDataSource});

  Future<List<QuestionModel>> getQuestions() => remoteDataSource.getQuestions();

  Future<OnboardingStatusModel> getStatus() => remoteDataSource.getStatus();

  Future<String> submitAssessment(List<String> selectedOptionIds) =>
      remoteDataSource.submitAssessment(selectedOptionIds);
}
