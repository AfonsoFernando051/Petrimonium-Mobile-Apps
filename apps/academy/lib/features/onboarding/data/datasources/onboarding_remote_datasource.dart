import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_academy/core/constants/api_constants.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

class OnboardingRemoteDataSource {
  final ApiClient apiClient;

  OnboardingRemoteDataSource({required this.apiClient});

  Future<List<QuestionModel>> getQuestions() async {
    final response = await apiClient.get(
      '${ApiConstants.onboardingQuestionsEndpoint}?lang=${Translator.currentLanguage}',
    );
    return _parseQuestions(response);
  }

  Future<OnboardingStatusModel> getStatus() async {
    final response = await apiClient.get(ApiConstants.onboardingStatusEndpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return OnboardingStatusModel.fromJson(data);
    }

    throw Exception('Failed to load onboarding status. Status code: ${response.statusCode}');
  }

  Future<String> submitAssessment(List<String> selectedOptionIds) async {
    final response = await apiClient.post(
      ApiConstants.onboardingSubmitEndpoint,
      {'selectedOptionIds': selectedOptionIds},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['profile'] as String;
    }

    throw Exception('Failed to submit onboarding. Status code: ${response.statusCode}');
  }

  List<QuestionModel> _parseQuestions(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Failed to load onboarding questions. Status code: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList();
  }
}

