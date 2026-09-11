import 'dart:convert';

import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_wallet/core/constants/api_constants.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

class OnboardingRemoteDataSource {
  final ApiClient apiClient;

  OnboardingRemoteDataSource({required this.apiClient});

  Future<OnboardingStatusModel> getStatus() async {
    final response = await apiClient.get(ApiConstants.onboardingStatusEndpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return OnboardingStatusModel.fromJson(data);
    }

    throw Exception('Failed to load onboarding status. Status code: ${response.statusCode}');
  }

  /// Submits the real investor-profile answers (goal, investment horizon,
  /// experience level) so the backend can classify an InvestorProfile from
  /// them — see `core/domain/assessment/AcademyOnboardingAnswers.java` (the
  /// backend contract is app-agnostic despite the class name: it accepts
  /// these same three signals from any client). Each parameter is already
  /// the wire value (`InvestorProfileGoalEnum.wireValue` etc.), keeping this
  /// datasource a plain network boundary with no enum-mapping logic.
  Future<String> submitAssessment({
    required String goal,
    required String investmentHorizon,
    required String experienceLevel,
  }) async {
    final response = await apiClient.post(ApiConstants.onboardingSubmitEndpoint, {
      'goal': goal,
      'investmentHorizon': investmentHorizon,
      'experienceLevel': experienceLevel,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['profile'] as String;
    }

    throw Exception('Failed to submit onboarding. Status code: ${response.statusCode}');
  }
}
