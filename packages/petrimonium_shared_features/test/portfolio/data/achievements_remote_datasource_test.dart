import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late AchievementsRemoteDataSource dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = AchievementsRemoteDataSource(apiClient: mockApiClient);
  });

  group('AchievementsRemoteDataSource.evaluate', () {
    test('returns the decoded evaluation JSON on 200', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => http.Response(
            jsonEncode({
              'unlockedAt': {'first_investment': '2024-01-01T00:00:00.000Z'},
              'newlyUnlockedCodes': ['first_investment'],
              'achievementXpTotal': 50,
            }),
            200,
          ));

      final result = await dataSource.evaluate();

      expect(result['achievementXpTotal'], 50);
      verify(() => mockApiClient.get(AchievementsRemoteDataSource.achievementsEndpoint)).called(1);
    });

    test('throws with the backend detail on a non-200 response', () async {
      when(() => mockApiClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode({'detail': 'Unauthorized'}), 401),
      );

      await expectLater(
        () => dataSource.evaluate(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Unauthorized'))),
      );
    });

    test('falls back to a generic message when the error body has no detail', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => http.Response('', 500));

      await expectLater(
        () => dataSource.evaluate(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Status Code: 500'))),
      );
    });
  });
}
