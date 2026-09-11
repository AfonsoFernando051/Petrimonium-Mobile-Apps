import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/onboarding/data/repositories/onboarding_repository.dart';

class MockOnboardingRemoteDataSource extends Mock implements OnboardingRemoteDataSource {}

void main() {
  late MockOnboardingRemoteDataSource mockDataSource;
  late OnboardingRepository repository;

  setUp(() {
    mockDataSource = MockOnboardingRemoteDataSource();
    repository = OnboardingRepository(remoteDataSource: mockDataSource);
  });

  group('getStatus', () {
    test('delegates to the data source and returns its result unchanged', () async {
      const status = OnboardingStatusModel(hasAnswered: true, profile: 'moderate');
      when(() => mockDataSource.getStatus()).thenAnswer((_) async => status);

      expect(await repository.getStatus(), status);
    });

    test('propagates a data source failure', () async {
      when(() => mockDataSource.getStatus()).thenThrow(Exception('boom'));

      expect(() => repository.getStatus(), throwsException);
    });
  });

  group('submitAssessment', () {
    test('passes the three answers straight through', () async {
      when(
        () => mockDataSource.submitAssessment(
          goal: any(named: 'goal'),
          investmentHorizon: any(named: 'investmentHorizon'),
          experienceLevel: any(named: 'experienceLevel'),
        ),
      ).thenAnswer((_) async => 'TACTICIAN');

      final result = await repository.submitAssessment(
        goal: 'INVEST_WITH_CONFIDENCE',
        investmentHorizon: 'MORE_THAN_FIVE_YEARS',
        experienceLevel: 'PRACTITIONER',
      );

      expect(result, 'TACTICIAN');
      verify(
        () => mockDataSource.submitAssessment(
          goal: 'INVEST_WITH_CONFIDENCE',
          investmentHorizon: 'MORE_THAN_FIVE_YEARS',
          experienceLevel: 'PRACTITIONER',
        ),
      ).called(1);
    });
  });
}
