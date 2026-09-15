import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/core/events/app_event.dart';
import 'package:petrimonium_wallet/core/events/app_event_bus.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/gamification_controller.dart';

/// In-memory [AchievementsLocalRepository] double — the real one persists to
/// `SharedPreferences`, unavailable in a plain unit test.
class FakeAchievementsLocalRepository implements AchievementsLocalRepository {
  Map<String, DateTime> _unlocked = {};

  @override
  Future<Map<String, DateTime>> loadUnlocked() async => _unlocked;

  @override
  Future<void> cacheUnlocked(Map<String, DateTime> unlockedAt) async {
    _unlocked = unlockedAt;
  }
}

/// In-memory [AchievementsRepository] double standing in for the real
/// backend call — the achievement-*qualification* logic itself now lives
/// server-side (see `EvaluateAchievementsUseCaseImplTest.java`), so this
/// test only verifies `GamificationController` correctly orchestrates
/// whatever the backend reports.
class FakeAchievementsRepository implements AchievementsRepository {
  AchievementEvaluationResult resultToReturn = AchievementEvaluationResult.empty;

  @override
  Future<AchievementEvaluationResult> evaluate() async => resultToReturn;

  @override
  AchievementsRemoteDataSource get remoteDataSource => throw UnimplementedError();
}

/// In-memory [GamificationRepository] double — the real one calls the
/// backend's `/api/v1/gamification/summary` endpoint.
class FakeGamificationRepository implements GamificationRepository {
  GamificationSummary summaryToReturn = GamificationSummary.empty;

  @override
  Future<GamificationSummary> fetchSummary() async => summaryToReturn;

  @override
  GamificationRemoteDataSource get remoteDataSource => throw UnimplementedError();
}

/// In-memory [MissionsRepository] double standing in for the real backend
/// call — mission progress/completion logic itself now lives server-side
/// (see `EvaluateMissionsUseCaseImplTest.java`), so this only verifies
/// `GamificationController` correctly orchestrates whatever the backend
/// reports.
class FakeMissionsRepository implements MissionsRepository {
  MissionEvaluationResult resultToReturn = MissionEvaluationResult.empty;
  Object? evaluateError;

  @override
  Future<MissionEvaluationResult> evaluate() async {
    if (evaluateError != null) throw evaluateError!;
    return resultToReturn;
  }

  @override
  MissionsRemoteDataSource get remoteDataSource => throw UnimplementedError();
}

/// `AppEventBus`'s broadcast controller notifies listeners asynchronously,
/// so a test that emits and then immediately asserts needs one more turn of
/// the event loop before the listener's callback has actually run.
Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAchievementsLocalRepository achievementsLocalRepository;
  late FakeAchievementsRepository achievementsRepository;
  late FakeGamificationRepository gamificationRepository;
  late FakeMissionsRepository missionsRepository;
  late GamificationController controller;

  setUp(() {
    achievementsLocalRepository = FakeAchievementsLocalRepository();
    achievementsRepository = FakeAchievementsRepository();
    gamificationRepository = FakeGamificationRepository();
    missionsRepository = FakeMissionsRepository();
    controller = GamificationController(
      achievementsLocalRepository: achievementsLocalRepository,
      achievementsRepository: achievementsRepository,
      gamificationRepository: gamificationRepository,
      missionsRepository: missionsRepository,
    );
  });

  tearDown(() {
    if (!controller.disposed) controller.dispose();
  });

  group('evaluate — achievements', () {
    // Achievement *qualification* is now real, server-side logic (see
    // EvaluateAchievementsUseCaseImplTest.java) — this only verifies
    // GamificationController correctly orchestrates whatever the backend
    // reports: caching it locally and reporting newly-unlocked ones exactly
    // once.
    test('reports newly-unlocked achievements from the backend and caches them locally', () async {
      achievementsRepository.resultToReturn = AchievementEvaluationResult(
        unlockedAt: {'first_investment': DateTime(2026, 1, 1)},
        newlyUnlockedCodes: {'first_investment'},
        achievementXpTotal: 50,
      );

      await controller.evaluate(currentNetWorth: 1200);

      expect(controller.newlyUnlocked.any((a) => a.id == 'first_investment'), isTrue);
      expect(controller.achievements.firstWhere((a) => a.id == 'first_investment').unlocked, isTrue);
      expect((await achievementsLocalRepository.loadUnlocked()).containsKey('first_investment'), isTrue);

      controller.clearNewlyUnlocked();
      expect(controller.newlyUnlocked, isEmpty);

      // A second evaluation where the backend reports no *new* unlocks
      // (already persisted server-side) must not re-report it as "newly"
      // unlocked.
      achievementsRepository.resultToReturn = AchievementEvaluationResult(
        unlockedAt: {'first_investment': DateTime(2026, 1, 1)},
        newlyUnlockedCodes: {},
        achievementXpTotal: 50,
      );
      await controller.evaluate(currentNetWorth: 1200);
      expect(controller.newlyUnlocked, isEmpty);
    });

    test('feeds the backend\'s real total XP into gamificationSummary', () async {
      gamificationRepository.summaryToReturn = const GamificationSummary(
        totalXp: 275,
        level: 3,
        xpIntoLevel: 25,
        xpForNextLevel: 100,
        currentStreak: 2,
        longestStreak: 5,
      );

      await controller.evaluate(currentNetWorth: 1200);

      expect(controller.gamificationSummary?.totalXp, 275);
      expect(controller.gamificationSummary?.currentStreak, 2);
    });
  });

  group('evaluate — missions', () {
    test('populates missions and newly-completed codes from the backend', () async {
      missionsRepository.resultToReturn = const MissionEvaluationResult(
        missions: [
          MissionStatus(
            code: 'daily_complete_lesson',
            period: MissionPeriod.daily,
            periodKey: '2026-08-19',
            progress: 1,
            target: 1,
            xpReward: 30,
            completed: true,
          ),
        ],
        newlyCompletedCodes: {'daily_complete_lesson'},
        missionXpTotal: 30,
      );

      await controller.evaluate(currentNetWorth: 1200);

      expect(controller.missions, hasLength(1));
      expect(controller.missions.first.code, 'daily_complete_lesson');
      expect(controller.newlyCompletedMissions, contains('daily_complete_lesson'));

      controller.clearNewlyCompletedMissions();
      expect(controller.newlyCompletedMissions, isEmpty);
    });

    test('emits a MissionCompletedEvent with the resolved title for each newly-completed mission', () async {
      final events = <AppEvent>[];
      final sub = AppEventBus.instance.stream.listen(events.add);
      addTearDown(sub.cancel);

      missionsRepository.resultToReturn = const MissionEvaluationResult(
        missions: [
          MissionStatus(
            code: 'daily_complete_lesson',
            period: MissionPeriod.daily,
            periodKey: '2026-08-19',
            progress: 1,
            target: 1,
            xpReward: 30,
            completed: true,
          ),
        ],
        newlyCompletedCodes: {'daily_complete_lesson'},
        missionXpTotal: 30,
      );

      await controller.evaluate(currentNetWorth: 1200);
      await flushMicrotasks();

      final missionEvents = events.whereType<MissionCompletedEvent>().toList();
      expect(missionEvents, hasLength(1));
      expect(missionEvents.single.missionTitle, 'Aula do Dia');
    });

    test('does not emit MissionCompletedEvent when nothing newly completed', () async {
      final events = <AppEvent>[];
      final sub = AppEventBus.instance.stream.listen(events.add);
      addTearDown(sub.cancel);

      missionsRepository.resultToReturn = const MissionEvaluationResult(
        missions: [
          MissionStatus(
            code: 'daily_complete_lesson',
            period: MissionPeriod.daily,
            periodKey: '2026-08-19',
            progress: 0,
            target: 1,
            xpReward: 30,
            completed: false,
          ),
        ],
        newlyCompletedCodes: {},
        missionXpTotal: 0,
      );

      await controller.evaluate(currentNetWorth: 1200);
      await flushMicrotasks();

      expect(events.whereType<MissionCompletedEvent>(), isEmpty);
    });

    test('a missions backend failure does not crash evaluate or clear prior mission state', () async {
      missionsRepository.resultToReturn = const MissionEvaluationResult(
        missions: [
          MissionStatus(
            code: 'daily_complete_lesson',
            period: MissionPeriod.daily,
            periodKey: '2026-08-19',
            progress: 0,
            target: 1,
            xpReward: 30,
            completed: false,
          ),
        ],
        newlyCompletedCodes: {},
        missionXpTotal: 0,
      );
      await controller.evaluate(currentNetWorth: 1200);
      expect(controller.missions, hasLength(1));

      missionsRepository.evaluateError = Exception('network down');
      await controller.evaluate(currentNetWorth: 1200);

      expect(controller.missions, hasLength(1));
    });
  });

  group('dispose safety', () {
    // GamificationController.evaluate() is the same "fire-and-forget from
    // initState-adjacent code, disposed before it resolves" shape as
    // PortfolioController.loadAll() — see
    // portfolio_controller_test.dart's own "dispose safety" group.
    test('a pending evaluate() completing after dispose() does not throw', () async {
      final pendingEvaluate = controller.evaluate(currentNetWorth: 1200);
      controller.dispose();

      await expectLater(pendingEvaluate, completes);
    });
  });
}
