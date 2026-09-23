import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';

/// Home's opening line — a greeting plus a streak badge, both real:
/// [userName] comes from the account's registered name (null while
/// unresolved, in which case a name-less greeting shows rather than
/// guessing), [streakDays] from the backend's real gamification summary
/// (`GamificationSummary.currentStreak`) — hidden entirely at 0 rather than
/// showing a meaningless "0 days".
///
/// [isFirstSession] picks "Bem-vindo" over "Bem-vindo de volta". Without it
/// Home greeted a user who had finished signing up seconds earlier as if
/// they were returning.
class HomeGreetingRow extends StatelessWidget {
  const HomeGreetingRow({super.key, this.userName, this.streakDays, this.isFirstSession = false});

  final String? userName;
  final int? streakDays;

  /// True only while this is the user's first run of the app — resolved from
  /// `OnboardingStateRepository.currentSessionCount()`. Defaults to false so
  /// an unresolved count greets a returning user, never the other way round.
  final bool isFirstSession;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final hasName = userName != null && userName!.isNotEmpty;
    final greeting = hasName
        ? Translator.translate(
            isFirstSession ? AppStrings.welcomeFirstTimeWithName : AppStrings.homeGreetingWithName,
            params: {'name': userName!},
          )
        : Translator.translate(isFirstSession ? AppStrings.welcomeFirstTime : AppStrings.welcomeBack);

    return Row(
      children: [
        Expanded(
          child: Text(
            greeting,
            style: TextStyle(color: tokens.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        if (streakDays != null && streakDays! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  Translator.translate(AppStrings.homeStreakDaysLabel, params: {'days': '$streakDays'}),
                  style: TextStyle(color: tokens.warning, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
