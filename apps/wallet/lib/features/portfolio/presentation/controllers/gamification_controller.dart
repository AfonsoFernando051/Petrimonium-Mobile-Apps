import 'package:flutter/foundation.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_wallet/core/events/app_event.dart';
import 'package:petrimonium_wallet/core/events/app_event_bus.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/models/achievement.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/models/achievement_catalog.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/models/mission_display_catalog.dart';

/// Owns everything the backend now decides authoritatively about the
/// player's engagement — achievement unlocks, mission progress, and total
/// XP/level — split out of `PortfolioController`, which owns real
/// holdings/summary/allocation/history and nothing about engagement.
/// Combining the two in one class meant "portfolio data changed" and
/// "gamification state changed" were indistinguishable reasons to rebuild,
/// and a change to one concern risked breaking a test for the other.
///
/// [evaluate] is meant to run every time the portfolio reloads, so
/// achievements/missions/XP never drift out of sync with the holdings that
/// justify them — see `PortfolioController.loadAll`, which is the one place
/// that calls it (via the optional `gamificationController` collaborator,
/// the same "optional injected collaborator" shape `PortfolioController`
/// already used for `MascotController`) so every existing entry point that
/// reloads or refreshes the portfolio (dashboard's initial load,
/// `AddAssetScreen`, `PurchaseHistoryCard`, `PassiveIncomeScreen`'s
/// pull-to-refresh) keeps re-evaluating gamification exactly as before this
/// split, with no changes needed at those call sites.
class GamificationController extends ChangeNotifier with SafeChangeNotifier {
  GamificationController({
    required AchievementsLocalRepository achievementsLocalRepository,
    required AchievementsRepository achievementsRepository,
    required GamificationRepository gamificationRepository,
    required MissionsRepository missionsRepository,
    MascotController? mascotController,
    AppEventBus? eventBus,
  }) : _achievementsLocalRepository = achievementsLocalRepository,
       _achievementsRepository = achievementsRepository,
       _gamificationRepository = gamificationRepository,
       _missionsRepository = missionsRepository,
       _mascotController = mascotController,
       _eventBus = eventBus ?? AppEventBus.instance;

  final AchievementsLocalRepository _achievementsLocalRepository;
  final AchievementsRepository _achievementsRepository;
  final GamificationRepository _gamificationRepository;
  final MissionsRepository _missionsRepository;
  final MascotController? _mascotController;
  final AppEventBus _eventBus;

  Map<String, DateTime> _unlockedAchievements = {};

  /// The backend's real XP/level/streak, refreshed on every [evaluate].
  /// Null until the first successful fetch — callers must not fabricate a
  /// placeholder value while it's null.
  GamificationSummary? gamificationSummary;

  /// Achievements that became unlocked on the *most recent* [evaluate] call
  /// — i.e. genuinely new this session, not just "unlocked at some point in
  /// the past" (diffed against what was already persisted before
  /// recomputing). The UI shows a celebration for these, then calls
  /// [clearNewlyUnlocked].
  List<Achievement> newlyUnlocked = [];

  void clearNewlyUnlocked() {
    newlyUnlocked = [];
  }

  /// The current period's real status for every mission
  /// (`GET /api/v1/missions`), refreshed on every [evaluate]. Empty until
  /// the first successful fetch.
  List<MissionStatus> missions = [];

  /// Mission codes newly completed on the *most recent* [evaluate] call —
  /// same "genuinely new this session" contract as [newlyUnlocked].
  Set<String> newlyCompletedMissions = {};

  void clearNewlyCompletedMissions() {
    newlyCompletedMissions = {};
  }

  List<Achievement> get achievements => AchievementCatalog.resolve(_unlockedAchievements);

  /// The backend is the sole authority on achievement unlocks, mission
  /// progress, and XP. [AchievementsRepository.evaluate] re-checks every
  /// achievement condition against the user's real, server-side portfolio
  /// and persists any new unlock; [MissionsRepository.evaluate] does the
  /// same for every mission's current daily/weekly period, purely from real
  /// lesson/module completion history; [GamificationRepository.fetchSummary]
  /// returns the real total XP (learning + achievements + missions) and
  /// level. All three calls are independently best-effort — offline, the
  /// achievement path falls back to the last-known-real cache rather than
  /// fabricating a number; missions have no such cache (each period resets
  /// anyway) and simply keep whatever was last successfully fetched.
  ///
  /// [currentNetWorth] is the real portfolio value at the time of this call
  /// (`PortfolioController.summary.currentValue`) — needed to feed
  /// `MascotController.evaluateEvolution`, which stores it on the pet
  /// profile as an informational fact but never gates evolution on it.
  Future<void> evaluate({required double currentNetWorth}) async {
    try {
      final result = await _achievementsRepository.evaluate();
      _unlockedAchievements = result.unlockedAt;
      await _achievementsLocalRepository.cacheUnlocked(result.unlockedAt);

      if (result.newlyUnlockedCodes.isNotEmpty) {
        newlyUnlocked = AchievementCatalog.resolve(
          _unlockedAchievements,
        ).where((a) => result.newlyUnlockedCodes.contains(a.id)).toList();
        // The in-screen celebration overlay (`newlyUnlocked` above) already
        // shows these; the bus emission is for other, decoupled listeners
        // (e.g. the pet companion's reaction messages) rather than a second UI.
        for (final achievement in newlyUnlocked) {
          _eventBus.emit(AchievementUnlockedEvent(achievement));
        }
      }
    } catch (_) {
      // Offline or backend unavailable — fall back to the last-known-real
      // cached unlock state rather than showing nothing or fabricating one.
      _unlockedAchievements = await _achievementsLocalRepository.loadUnlocked();
    }

    try {
      final result = await _missionsRepository.evaluate();
      missions = result.missions;
      newlyCompletedMissions = result.newlyCompletedCodes;
      // Mirrors the achievement-unlock loop above: the in-screen celebration
      // (`newlyCompletedMissions`) already shows these on the Portfolio tab;
      // the bus emission is for decoupled listeners like the pet companion.
      for (final code in result.newlyCompletedCodes) {
        _eventBus.emit(MissionCompletedEvent(MissionDisplayCatalog.forCode(code).title));
      }
    } catch (_) {
      // Offline or backend unavailable — keep whatever mission state was
      // last successfully fetched rather than showing nothing.
    }

    try {
      gamificationSummary = await _gamificationRepository.fetchSummary();
      await _mascotController?.evaluateEvolution(currentNetWorth, gamificationSummary!.totalXp);
    } catch (_) {
      // Offline or backend unavailable — keep whatever XP/level the mascot
      // already had rather than overwriting it with a guess.
    }

    notifySafely();
  }
}
