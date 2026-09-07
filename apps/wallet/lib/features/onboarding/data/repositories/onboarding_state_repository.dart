import 'package:shared_preferences/shared_preferences.dart';

import 'package:petrimonium/core/utils/user_scoped_prefs.dart';

/// After this many app sessions with portfolio still unconnected, the pet
/// may gently nudge the user on Home (see `shouldShowPortfolioReminder`).
const int kPortfolioReminderAfterSessions = 3;

/// After a reminder is shown, the pet waits at least this many sessions
/// before mentioning it again — reminders should never feel intrusive.
const int kPortfolioReminderCooldownSessions = 3;

/// Local-only (SharedPreferences) flags for the redesigned onboarding flow:
/// whether the player has chosen a financial goal, finished the tutorial,
/// and how they left the (now fully optional) portfolio step. There is no
/// backend field for any of this — it only decides which screen the app
/// opens to and what Home shows, mirroring `PetPreferencesRepository`'s
/// "local-only, nothing else consumes it yet" pattern.
///
/// Every key is scoped to the currently logged-in account (see
/// [UserScopedPrefs]) — switching accounts on the same device must never
/// route or nudge one user based on another's onboarding progress (Demanda
/// #57). A device that already has data under the old, unscoped key names
/// is migrated onto the current account's scoped keys the first time each
/// is read, same pattern as `AchievementsLocalRepository`.
class OnboardingStateRepository {
  static const _hasSetGoalKey = 'onboarding_has_set_goal';
  static const _tutorialCompletedKey = 'onboarding_tutorial_completed';
  static const _portfolioStepDoneKey = 'onboarding_portfolio_step_done';
  static const _portfolioConnectedKey = 'onboarding_portfolio_connected';
  static const _portfolioSkippedAtKey = 'onboarding_portfolio_skipped_at';
  static const _sessionCountKey = 'onboarding_session_count';
  static const _reminderShownAtSessionKey =
      'onboarding_reminder_shown_at_session';
  static const _portfolioActivationSeenKey = 'portfolio_activation_seen';
  static const _mentorWelcomeSeenKey = 'onboarding_mentor_welcome_seen';
  static const _quickSetupDoneKey = 'onboarding_quick_setup_done';

  /// Wallet's 2-screen mini-onboarding gate — see `MentorWelcomeScreen`.
  /// Unlike [hasSetGoal]/[isTutorialCompleted] (still defined below for the
  /// old 7-step flow, now unreachable from `StartRouteResolver` but kept
  /// around undeleted per the "defer cleanup" pattern), this is the gate
  /// Wallet's `StartRouteResolver` actually reads.
  Future<bool> hasSeenMentorWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(await _migrateBool(prefs, _mentorWelcomeSeenKey)) ?? false;
  }

  Future<void> markMentorWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await UserScopedPrefs.key(_mentorWelcomeSeenKey), true);
  }

  Future<bool> hasCompletedQuickSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(await _migrateBool(prefs, _quickSetupDoneKey)) ?? false;
  }

  Future<void> markQuickSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await UserScopedPrefs.key(_quickSetupDoneKey), true);
  }

  Future<bool> hasSetGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(await _migrateBool(prefs, _hasSetGoalKey)) ?? false;
  }

  Future<void> setGoalChosen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await UserScopedPrefs.key(_hasSetGoalKey), true);
  }

  Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(await _migrateBool(prefs, _tutorialCompletedKey)) ?? false;
  }

  Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await UserScopedPrefs.key(_tutorialCompletedKey), true);
  }

  Future<bool> isPortfolioStepDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(await _migrateBool(prefs, _portfolioStepDoneKey)) ?? false;
  }

  Future<bool> isPortfolioConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(await _migrateBool(prefs, _portfolioConnectedKey)) ?? false;
  }

  /// Marks the portfolio step as resolved via import/manual entry — the
  /// user has real holdings now, so Home shows live data, not placeholders.
  Future<void> markPortfolioConnected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await UserScopedPrefs.key(_portfolioStepDoneKey), true);
    await prefs.setBool(await UserScopedPrefs.key(_portfolioConnectedKey), true);
    await prefs.remove(await UserScopedPrefs.key(_portfolioSkippedAtKey));
  }

  /// Marks the portfolio step as resolved via "Skip For Now" — Home shows
  /// placeholders, and the pet may nudge the user again later.
  Future<void> markPortfolioSkipped({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await UserScopedPrefs.key(_portfolioStepDoneKey), true);
    await prefs.setBool(await UserScopedPrefs.key(_portfolioConnectedKey), false);
    await prefs.setString(
      await UserScopedPrefs.key(_portfolioSkippedAtKey),
      (now ?? DateTime.now()).toIso8601String(),
    );
  }

  /// Increments and returns the number of app sessions (cold starts) so
  /// far — call once per app boot. Used to pace the reminder cooldown.
  Future<int> incrementSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _migrateInt(prefs, _sessionCountKey);
    final next = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, next);
    return next;
  }

  /// The session count as of the most recent [incrementSessionCount] call
  /// (i.e. this session's count), without incrementing it again.
  Future<int> currentSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(await _migrateInt(prefs, _sessionCountKey)) ?? 0;
  }

  Future<void> markReminderShown(int atSession) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(await UserScopedPrefs.key(_reminderShownAtSessionKey), atSession);
  }

  /// Whether the pet should nudge the user about connecting their portfolio
  /// this session: only if they explicitly skipped (never if they simply
  /// haven't reached that step yet), enough sessions have passed since the
  /// skip, and enough sessions have passed since the last reminder.
  Future<bool> shouldShowPortfolioReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final skipped =
        prefs.getBool(await _migrateBool(prefs, _portfolioConnectedKey)) == false &&
        prefs.getString(await _migrateString(prefs, _portfolioSkippedAtKey)) != null;
    if (!skipped) return false;

    final sessionCount = prefs.getInt(await _migrateInt(prefs, _sessionCountKey)) ?? 0;
    if (sessionCount < kPortfolioReminderAfterSessions) return false;

    final lastShown = prefs.getInt(await _migrateInt(prefs, _reminderShownAtSessionKey));
    if (lastShown != null &&
        sessionCount - lastShown < kPortfolioReminderCooldownSessions) {
      return false;
    }
    return true;
  }

  /// Whether the Portfolio tab's full activation intro (title + "do you
  /// already invest?" question) has already been shown once. Deliberately
  /// separate from [isPortfolioConnected]/[markPortfolioSkipped] — those
  /// resolve the *onboarding* step and `StartRouteResolver` explicitly never
  /// re-routes on zero holdings alone, whereas this flag only decides
  /// whether the Portfolio tab shows the full intro or a shorter, returning
  /// nudge while holdings stay at zero.
  Future<bool> hasSeenPortfolioActivation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(await _migrateBool(prefs, _portfolioActivationSeenKey)) ?? false;
  }

  Future<void> markPortfolioActivationSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await UserScopedPrefs.key(_portfolioActivationSeenKey), true);
  }

  /// Returns [baseKey]'s scoped form, migrating over any value still sitting
  /// under the old unscoped key the first time it's read on this device —
  /// see `AchievementsLocalRepository._migrateStringList` for the same
  /// pattern and its rationale. One helper per `SharedPreferences` value
  /// type, since it has no generic get/set pair.
  Future<String> _migrateBool(SharedPreferences prefs, String baseKey) async {
    final scopedKey = await UserScopedPrefs.key(baseKey);
    if (!prefs.containsKey(scopedKey)) {
      final legacy = prefs.getBool(baseKey);
      if (legacy != null) {
        await prefs.setBool(scopedKey, legacy);
        await prefs.remove(baseKey);
      }
    }
    return scopedKey;
  }

  Future<String> _migrateInt(SharedPreferences prefs, String baseKey) async {
    final scopedKey = await UserScopedPrefs.key(baseKey);
    if (!prefs.containsKey(scopedKey)) {
      final legacy = prefs.getInt(baseKey);
      if (legacy != null) {
        await prefs.setInt(scopedKey, legacy);
        await prefs.remove(baseKey);
      }
    }
    return scopedKey;
  }

  Future<String> _migrateString(SharedPreferences prefs, String baseKey) async {
    final scopedKey = await UserScopedPrefs.key(baseKey);
    if (!prefs.containsKey(scopedKey)) {
      final legacy = prefs.getString(baseKey);
      if (legacy != null) {
        await prefs.setString(scopedKey, legacy);
        await prefs.remove(baseKey);
      }
    }
    return scopedKey;
  }
}
