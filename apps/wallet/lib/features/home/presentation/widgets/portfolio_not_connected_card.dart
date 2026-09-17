import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/constants/app_colors.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/home_pet_hero.dart';
import 'package:petrimonium_wallet/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';

/// Which "no investments yet" screen this empty state renders on. Both
/// share the same shape (pet hero, title/subtitle, CTA into
/// [AddAssetScreen], B3 row) but differ in a few concrete details the
/// reference design specifies per screen.
enum PortfolioEmptyStateVariant {
  /// Início's richer treatment: a static companion speech bubble above a
  /// bigger pet, and a 2×2 row of locked KPI placeholders (Patrimônio,
  /// Rentabilidade, Proventos, Insights) teasing what appears once a first
  /// asset exists.
  home,

  /// Carteira's plainer treatment: no companion bubble, a smaller pet, and
  /// no KPI placeholders — Início already carries that teaser, so Carteira
  /// doesn't repeat it.
  carteira,
}

/// The empty-portfolio placeholder shown on both Início and Carteira until
/// the user has registered a first asset — the app must stay fully usable
/// without a portfolio, so this replaces the wealth/holdings sections
/// instead of blocking either screen. Leads with the Pet as a big, living
/// companion (see `HomePetHero`) rather than a small icon: "o PET deve ser
/// maior e aparecer mais no dashboard, nao ficar pequeno e discreto."
///
/// There is no real brokerage connection anywhere in this app yet (see
/// `docs/ECOSYSTEM.md`) — the CTA opens [AddAssetScreen], the only way
/// holdings ever get in today. The gamified, multi-asset onboarding wizard
/// this used to open (`InvestmentConfigurationScreen`) was retired —
/// [AddAssetScreen]'s plain, single-asset "Mentor mais discreto" form now
/// covers both the zero-holdings first-time entry and adding one more asset
/// later, instead of keeping two different screens for the same job. The B3
/// option is shown so the user knows a second, automatic way is coming, but
/// only offers a "coming soon" acknowledgement, not a real connection.
class PortfolioNotConnectedCard extends StatelessWidget {
  const PortfolioNotConnectedCard({
    super.key,
    required this.mascotController,
    required this.controller,
    this.anchor,
    this.variant = PortfolioEmptyStateVariant.home,
  });

  final MascotController mascotController;
  final PortfolioController controller;
  final PetSpeechBubbleAnchor? anchor;
  final PortfolioEmptyStateVariant variant;

  bool get _isHome => variant == PortfolioEmptyStateVariant.home;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isHome) ...[const _CompanionCaption(), const SizedBox(height: 8)],
        Center(
          child: HomePetHero(mascotController: mascotController, anchor: anchor, size: _isHome ? 172 : 120),
        ),
        const SizedBox(height: 18),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Column(
              children: [
                Text(
                  Translator.translate(_isHome ? AppStrings.homeEmptyStateTitle : AppStrings.carteiraEmptyStateTitle),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  Translator.translate(_isHome ? AppStrings.homeEmptyStateBody : AppStrings.carteiraEmptyStateBody),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        if (_isHome) ...[const SizedBox(height: 18), const _EmptyKpiPlaceholderGrid()],
        const SizedBox(height: 18),
        GameButton(
          label: Translator.translate(AppStrings.portfolioEmptyStateCta),
          icon: Icons.arrow_forward,
          iconTrailing: true,
          gradientColors: const [AppColors.neonViolet, AppColors.neonCyan],
          height: 52,
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddAssetScreen(controller: controller)));
          },
        ),
        if (kShowB3ConnectRow) ...[const SizedBox(height: 10), _B3ConnectRow(tokens: tokens)],
      ],
    );
  }
}

/// The companion's own static speech-bubble line above the big pet on
/// Início only — not routed through `PetCompanionController`'s contextual
/// message queue, since it's this specific empty state's permanent framing
/// (always true whenever it's shown), not a transient nudge with cooldown/
/// priority rules. Reuses the shared [ComicBubblePainter] the dynamic
/// companion bubbles use, so the tail/border chrome reads as the same
/// visual language, just always-on here instead of ephemeral.
class _CompanionCaption extends StatelessWidget {
  const _CompanionCaption();

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: CustomPaint(
          painter: ComicBubblePainter(
            gradient: LinearGradient(
              colors: [AppColors.neonCyan.withValues(alpha: 0.08), AppColors.neonCyan.withValues(alpha: 0.08)],
            ),
            borderColor: AppColors.neonCyan.withValues(alpha: 0.4),
            glowColor: Colors.transparent,
            tailPosition: PetBubbleTailPosition.bottomCenter,
            borderRadius: 18,
            strokeWidth: 1.5,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    Translator.translate(AppStrings.companionBadgeLabel),
                    style: const TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Translator.translate(AppStrings.portfolioNotConnectedPetCaption),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textPrimary, fontSize: 13.5, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Início's four locked KPI teasers (Patrimônio, Rentabilidade, Proventos,
/// Insights) — bare labels with no figures, since there is no real
/// portfolio to compute them from yet. Same real tiles
/// (`PortfolioKpiGrid`)/insight (`MentorInsightCard`) unlock once a first
/// asset exists.
class _EmptyKpiPlaceholderGrid extends StatelessWidget {
  const _EmptyKpiPlaceholderGrid();

  @override
  Widget build(BuildContext context) {
    final labels = [
      Translator.translate(AppStrings.homeEmptyKpiWealthLabel),
      Translator.translate(AppStrings.homeEmptyKpiReturnLabel),
      Translator.translate(AppStrings.homeEmptyKpiProventosLabel),
      Translator.translate(AppStrings.homeEmptyKpiInsightsLabel),
    ];
    return Column(
      children: [
        Row(children: [_tile(context, labels[0]), const SizedBox(width: 8), _tile(context, labels[1])]),
        const SizedBox(height: 8),
        Row(children: [_tile(context, labels[2]), const SizedBox(width: 8), _tile(context, labels[3])]),
      ],
    );
  }

  Widget _tile(BuildContext context, String label) {
    final tokens = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.textPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.border),
        ),
        child: Text(
          label,
          style: TextStyle(color: tokens.textTertiary, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Kept off for now: a real B3 sync (via an Open Finance aggregator like
/// Pluggy) costs real money per connected account, and there's no revenue
/// yet to justify that spend — see the backend's `B3RealPortfolioSyncAdapter`
/// doc for the matching decision on that side. Flip this back to `true`
/// once the app is generating revenue and B3 sync becomes worth building;
/// the row itself, its strings, and the "coming soon" copy all stay intact
/// so re-enabling is a one-line change, not a rebuild. Deliberately a
/// mutable top-level var, not `const` — `portfolio_not_connected_card_test.dart`
/// flips it on to keep exercising the real tap-to-snack behavior while it's
/// hidden from production users.
bool kShowB3ConnectRow = false;

/// The B3-sync option — when [kShowB3ConnectRow] is on, always visible so
/// the user knows a second, automatic way of bringing in assets is planned,
/// but there is no real integration to open yet (see class doc), so tapping
/// only acknowledges that with a "coming soon" snack instead of navigating
/// anywhere.
class _B3ConnectRow extends StatelessWidget {
  const _B3ConnectRow({required this.tokens});

  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => GameSnack.show(context, Translator.translate(AppStrings.comingSoonSnack)),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: tokens.textPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                Translator.translate(AppStrings.connectAssetsB3Cta),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.textPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                Translator.translate(AppStrings.connectAssetsB3Badge),
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
