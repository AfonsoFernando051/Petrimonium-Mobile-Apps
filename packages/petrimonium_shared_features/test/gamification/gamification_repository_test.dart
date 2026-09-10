import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

class MockGamificationRemoteDataSource extends Mock implements GamificationRemoteDataSource {}

void main() {
  late MockGamificationRemoteDataSource mockDataSource;
  late GamificationRepository repository;

  setUp(() {
    mockDataSource = MockGamificationRemoteDataSource();
    repository = GamificationRepository(remoteDataSource: mockDataSource);
  });

  group('fetchSummary', () {
    test('maps the raw JSON into a GamificationSummary', () async {
      when(() => mockDataSource.fetchSummary()).thenAnswer(
        (_) async => {
          'totalXp': 220,
          'level': 3,
          'xpIntoLevel': 20,
          'xpForNextLevel': 100,
          'currentStreak': 5,
          'longestStreak': 12,
        },
      );

      final summary = await repository.fetchSummary();

      expect(summary.totalXp, 220);
      expect(summary.level, 3);
      expect(summary.currentStreak, 5);
      expect(summary.longestStreak, 12);
    });

    test('propagates a datasource failure', () async {
      when(() => mockDataSource.fetchSummary()).thenThrow(Exception('backend unreachable'));

      expect(() => repository.fetchSummary(), throwsException);
    });
  });
}
