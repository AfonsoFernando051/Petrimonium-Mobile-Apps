import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/core/constants/api_constants.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_wallet/features/onboarding/data/datasources/onboarding_remote_datasource.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late OnboardingRemoteDataSource dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = OnboardingRemoteDataSource(apiClient: mockApiClient);
  });

  group('getStatus', () {
    test('parses hasAnswered/profile on 200', () async {
      when(
        () => mockApiClient.get(any()),
      ).thenAnswer((_) async => http.Response(jsonEncode({'hasAnswered': true, 'profile': 'moderate'}), 200));

      final result = await dataSource.getStatus();

      expect(result.hasAnswered, isTrue);
      expect(result.profile, 'moderate');
      verify(() => mockApiClient.get(ApiConstants.onboardingStatusEndpoint)).called(1);
    });

    test('throws an Exception on a non-200 response', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => http.Response('', 401));

      await expectLater(
        () => dataSource.getStatus(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('401'))),
      );
    });
  });

  group('submitAssessment', () {
    test('posts the three wire-value answers and returns the resulting profile on 200', () async {
      when(
        () => mockApiClient.post(any(), any()),
      ).thenAnswer((_) async => http.Response(jsonEncode({'profile': 'ADVENTURER'}), 200));

      final result = await dataSource.submitAssessment(
        goal: 'INVEST_WITH_CONFIDENCE',
        investmentHorizon: 'MORE_THAN_FIVE_YEARS',
        experienceLevel: 'PRACTITIONER',
      );

      expect(result, 'ADVENTURER');
      verify(
        () => mockApiClient.post(ApiConstants.onboardingSubmitEndpoint, {
          'goal': 'INVEST_WITH_CONFIDENCE',
          'investmentHorizon': 'MORE_THAN_FIVE_YEARS',
          'experienceLevel': 'PRACTITIONER',
        }),
      ).called(1);
    });

    test('throws an Exception on a non-200 response', () async {
      when(() => mockApiClient.post(any(), any())).thenAnswer((_) async => http.Response('', 400));

      await expectLater(
        () => dataSource.submitAssessment(goal: 'X', investmentHorizon: 'Y', experienceLevel: 'Z'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('400'))),
      );
    });
  });
}
