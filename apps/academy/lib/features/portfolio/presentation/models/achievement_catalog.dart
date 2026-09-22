import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import 'achievement.dart';

/// This product's wording and iconography for the shared achievement rules.
///
/// The ids, XP rewards and qualifying conditions live in
/// `AchievementRules` — they have to match the backend's Java
/// `AchievementCatalog` exactly, and having one copy of them halves the
/// hand-sync drift risk that file's comment warns about. What is here is
/// only how this app *says* each achievement, which is why extracting the
/// rules did not require deciding whose copy wins.
abstract final class AchievementCatalog {
  static const Map<String, IconData> _icons = {
    'first_investment': Icons.flag_circle,
    'first_dividend': Icons.attach_money,
    'positive_return': Icons.trending_up,
    'portfolio_10k': Icons.savings,
    'portfolio_50k': Icons.account_balance,
    'diversification_master': Icons.hub,
    'etf_collector': Icons.pie_chart,
    'hundred_days': Icons.calendar_month,
    'long_term_investor': Icons.emoji_events,
    'dividend_hunter': Icons.paid,
  };

  static ({String title, String description, IconData icon}) _copyFor(String id) => (
    title: switch (id) {
      'first_investment' => Translator.translate(AppStrings.achievementFirstInvestmentTitle),
      'first_dividend' => Translator.translate(AppStrings.achievementFirstDividendTitle),
      'positive_return' => Translator.translate(AppStrings.achievementPositiveReturnTitle),
      'portfolio_10k' => Translator.translate(AppStrings.achievementPortfolio10kTitle),
      'portfolio_50k' => Translator.translate(AppStrings.achievementPortfolio50kTitle),
      'diversification_master' => Translator.translate(AppStrings.achievementDiversificationMasterTitle),
      'etf_collector' => Translator.translate(AppStrings.achievementEtfCollectorTitle),
      'hundred_days' => Translator.translate(AppStrings.achievementHundredDaysTitle),
      'long_term_investor' => Translator.translate(AppStrings.achievementLongTermInvestorTitle),
      'dividend_hunter' => Translator.translate(AppStrings.achievementDividendHunterTitle),
      _ => id,
    },
    description: switch (id) {
      'first_investment' => Translator.translate(AppStrings.achievementFirstInvestmentDescription),
      'first_dividend' => Translator.translate(AppStrings.achievementFirstDividendDescription),
      'positive_return' => Translator.translate(AppStrings.achievementPositiveReturnDescription),
      'portfolio_10k' => Translator.translate(AppStrings.achievementPortfolio10kDescription),
      'portfolio_50k' => Translator.translate(AppStrings.achievementPortfolio50kDescription),
      'diversification_master' => Translator.translate(AppStrings.achievementDiversificationMasterDescription),
      'etf_collector' => Translator.translate(AppStrings.achievementEtfCollectorDescription),
      'hundred_days' => Translator.translate(AppStrings.achievementHundredDaysDescription),
      'long_term_investor' => Translator.translate(AppStrings.achievementLongTermInvestorDescription),
      'dividend_hunter' => Translator.translate(AppStrings.achievementDividendHunterDescription),
      _ => '',
    },
    icon: _icons[id] ?? Icons.emoji_events,
  );

  /// XP preview — delegates to the shared rules.
  static int totalXpFor(Set<String> unlockedIds) => AchievementRules.totalXpFor(unlockedIds);

  /// IDs whose condition is met right now — delegates to the shared rules.
  static Set<String> qualifiedIds(PortfolioStats stats) => AchievementRules.qualifiedIds(stats);

  /// Builds the full display list in the shared rules' declaration order,
  /// `unlocked` sourced from persisted state only (never re-derived live), so
  /// a later dip in net worth can't hide an achievement already earned.
  static List<Achievement> resolve(Map<String, DateTime> unlockedAt) {
    return AchievementRules.all.map((rule) {
      final copy = _copyFor(rule.id);
      return Achievement(
        id: rule.id,
        title: copy.title,
        description: copy.description,
        icon: copy.icon,
        xpReward: rule.xpReward,
        unlocked: unlockedAt.containsKey(rule.id),
        unlockedAt: unlockedAt[rule.id],
      );
    }).toList();
  }
}
