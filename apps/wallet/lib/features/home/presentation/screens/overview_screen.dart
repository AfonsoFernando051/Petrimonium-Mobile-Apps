import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/display_name.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/core/widgets/layer_chip.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/home_pet_hero.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/mentor_insight_card.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/portfolio/domain/entities/wealth_change_breakdown.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/allocation_donut_card.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/portfolio_kpi_grid.dart';

/// Wallet's "Início" — the condensed patrimônio + Mentor dashboard. In the
/// reference design's order: a greeting, the Mentor's one interpretation for
/// the session, the four headline KPIs ([PortfolioKpiGrid] — patrimônio,
/// lucro, proventos, rentabilidade, with the source/timestamp stated once
/// for the whole block), a real valorização/aportes/rendimentos breakdown
/// for the trailing 30 days (`PortfolioController.wealthChange30d`, computed
/// client-side from real lot/dividend data), and a compact "Sua carteira"
/// composition preview linking into the full Carteira tab — the trailing-12-
/// month wealth-evolution chart and the complete holdings list live there
/// instead (`CarteiraScreen`), not here.
///
/// No own `Scaffold`/`AppBar`/background — embedded directly in
/// `DashboardScreen`'s shared chrome.
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    required this.controller,
    required this.onOpenMentor,
    required this.onOpenCarteira,
    required this.mascotController,
    this.heroAnchor,
  });

  final PortfolioController controller;

  /// Opens the Mentor tab, optionally resuming a specific conversation
  /// (Home's Mentor card's "Por que estou vendo isto?") — `null` opens a
  /// blank chat.
  final ValueChanged<int?> onOpenMentor;

  /// Opens the Carteira tab — the "Sua carteira" preview card's
  /// "Ver carteira completa" link.
  final VoidCallback onOpenCarteira;

  /// Drives the big [HomePetHero] treatment — shown large in the
  /// empty-portfolio state and smaller alongside the greeting once a
  /// portfolio exists (`DashboardScreen` owns the one instance for the
  /// whole session, same as the AppBar's small companion avatar).
  final MascotController mascotController;

  /// Registers wherever [HomePetHero] actually renders on Home as the Pet's
  /// on-screen position, so `PetSpeechBubbleOverlay` can glue a contextual
  /// message to it instead of it going nowhere
  /// (`DashboardScreen._heroAnchor`).
  final PetSpeechBubbleAnchor? heroAnchor;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
    // Cached/deduped after the first call — safe to call unconditionally so
    // the wealth-change card's real rendimentos figure isn't stuck at 0.
    widget.controller.loadDividendRadarIfNeeded();
  }

  Future<void> _loadDisplayName() async {
    final email = await DI.authRepository.getSavedEmail();
    final name = deriveDisplayNameFromEmail(email);
    if (!mounted || name == null) return;
    setState(() => _displayName = name);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.isLoading && controller.holdings.isEmpty && controller.error == null) {
      return const AppLoadingIndicator();
    }

    final hasPortfolio = controller.holdings.isNotEmpty;

    return RefreshIndicator(
      color: context.colors.primary,
      backgroundColor: context.colors.surfaceElevated,
      onRefresh: controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _Greeting(displayName: _displayName)),
                // Only alongside the greeting once a portfolio exists — the
                // empty state already leads with the big hero treatment
                // inside PortfolioNotConnectedCard, so this avoids showing
                // the Pet twice on Home at once.
                if (hasPortfolio) ...[
                  const SizedBox(width: 12),
                  HomePetHero(
                    mascotController: widget.mascotController,
                    anchor: widget.heroAnchor,
                    size: 56,
                    showGlow: false,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            MentorInsightCard(onOpenMentor: widget.onOpenMentor),

            if (controller.error != null) ...[
              ErrorBanner(
                message: 'Não foi possível atualizar seus dados. Puxe para atualizar.',
                onRetry: controller.refresh,
              ),
              const SizedBox(height: 16),
            ],

            if (!hasPortfolio)
              PortfolioNotConnectedCard(
                mascotController: widget.mascotController,
                controller: controller,
                anchor: widget.heroAnchor,
              )
            else ...[
              PortfolioKpiGrid(controller: controller),
              const SizedBox(height: 16),
              _WealthChangeCard(breakdown: controller.wealthChange30d),
              const SizedBox(height: 16),
              AllocationDonutCard(allocation: controller.allocation, totalValue: controller.summary.currentValue),
              const SizedBox(height: 10),
              _ViewFullCarteiraLink(onTap: widget.onOpenCarteira),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.displayName});

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translator.translate(AppStrings.homeGreetingLabel),
          style: TextStyle(color: tokens.textSecondary, fontSize: 13),
        ),
        if (displayName != null) ...[
          const SizedBox(height: 2),
          Text(
            displayName!,
            style: TextStyle(color: tokens.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}

class _WealthChangeCard extends StatelessWidget {
  const _WealthChangeCard({required this.breakdown});

  final WealthChangeBreakdown? breakdown;

  String _signed(double value) => value >= 0 ? '+${AppFormatters.currency(value)}' : AppFormatters.currency(value);

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final breakdown = this.breakdown;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Translator.translate(AppStrings.homeChangeSectionTitle),
            style: TextStyle(color: tokens.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
          const SizedBox(height: 12),
          LayerChip(layer: DataLayer.calculation, label: Translator.translate(AppStrings.homeChangeCalcChipLabel)),
          const SizedBox(height: 12),
          if (breakdown == null)
            Text(
              Translator.translate(AppStrings.homeChangeNotEnoughHistoryNote),
              style: TextStyle(color: tokens.textSecondary, fontSize: 13, height: 1.4),
            )
          else ...[
            _ChangeRow(
              label: Translator.translate(AppStrings.homeChangeValorizacaoLabel),
              value: _signed(breakdown.valorizacao),
              tokens: tokens,
            ),
            const SizedBox(height: 8),
            _ChangeRow(
              label: Translator.translate(AppStrings.homeChangeAportesLabel),
              value: _signed(breakdown.aportes),
              tokens: tokens,
            ),
            const SizedBox(height: 8),
            _ChangeRow(
              label: Translator.translate(AppStrings.homeChangeRendimentosLabel),
              value: _signed(breakdown.rendimentos),
              tokens: tokens,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Ver carteira completa →" — Início's "Sua carteira" preview card's link
/// into the full Carteira tab (evolution chart, filters, complete holdings
/// list), mirroring the same pattern Home's Mentor/Academy cards use for
/// their own "ver mais" links.
class _ViewFullCarteiraLink extends StatelessWidget {
  const _ViewFullCarteiraLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          Translator.translate(AppStrings.homeViewFullCarteiraCta),
          style: TextStyle(color: context.colors.primary, fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.label, required this.value, required this.tokens});

  final String label;
  final String value;
  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: tokens.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
