import 'package:flutter/material.dart';
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
  static const Map<String, ({String title, String description, IconData icon})> _copy = {
    'first_investment': (
      title: 'Primeiro Investimento',
      description: 'Registrou seu primeiro ativo no portfólio.',
      icon: Icons.flag_circle,
    ),
    'first_dividend': (
      title: 'Primeiro Dividendo',
      description: 'Possui ao menos um ativo com geração de renda passiva.',
      icon: Icons.attach_money,
    ),
    'positive_return': (
      title: 'Primeiro Lucro',
      description: 'Seu portfólio atingiu retorno positivo.',
      icon: Icons.trending_up,
    ),
    'portfolio_10k': (
      title: 'Patamar de R\$10 mil',
      description: 'Alcançou R\$10.000 em patrimônio investido.',
      icon: Icons.savings,
    ),
    'portfolio_50k': (
      title: 'Patamar de R\$50 mil',
      description: 'Alcançou R\$50.000 em patrimônio investido.',
      icon: Icons.account_balance,
    ),
    'diversification_master': (
      title: 'Mestre da Diversificação',
      description: 'Investiu em 4 ou mais categorias de ativos.',
      icon: Icons.hub,
    ),
    'etf_collector': (
      title: 'Colecionador de ETFs',
      description: 'Reuniu 3 ou mais ETFs/fundos distintos.',
      icon: Icons.pie_chart,
    ),
    'hundred_days': (
      title: '100 Dias Investindo',
      description: 'Manteve investimentos ativos por 100 dias.',
      icon: Icons.calendar_month,
    ),
    'long_term_investor': (
      title: 'Investidor de Longo Prazo',
      description: 'Manteve investimentos ativos por 1 ano.',
      icon: Icons.emoji_events,
    ),
    'dividend_hunter': (
      title: 'Caçador de Dividendos',
      description: 'Alcançou R\$1.000/ano em renda passiva estimada.',
      icon: Icons.paid,
    ),
  };

  /// XP preview — delegates to the shared rules.
  static int totalXpFor(Set<String> unlockedIds) => AchievementRules.totalXpFor(unlockedIds);

  /// IDs whose condition is met right now — delegates to the shared rules.
  static Set<String> qualifiedIds(PortfolioStats stats) => AchievementRules.qualifiedIds(stats);

  /// Builds the full display list in the shared rules' declaration order,
  /// `unlocked` sourced from persisted state only (never re-derived live), so
  /// a later dip in net worth can't hide an achievement already earned.
  static List<Achievement> resolve(Map<String, DateTime> unlockedAt) {
    return AchievementRules.all.map((rule) {
      final copy = _copy[rule.id]!;
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
