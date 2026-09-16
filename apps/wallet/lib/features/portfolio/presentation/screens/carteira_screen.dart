import 'package:flutter/material.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/add_asset_icon_button.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/allocation_donut_card.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/holdings_section.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/wealth_evolution_bar_card.dart';

/// Wallet's "Carteira" — the full portfolio detail screen: patrimônio
/// investido, the trailing-12-month wealth evolution chart, the allocation
/// donut and the complete holdings list. Split out of "Início" (which keeps
/// only a condensed summary + a "Ver carteira completa" link into this
/// screen) per the reference design's separate Home/Carteira tabs.
///
/// No own `Scaffold`/`AppBar`/background — embedded directly in
/// `DashboardScreen`'s shared chrome, same as `OverviewScreen`.
class CarteiraScreen extends StatelessWidget {
  const CarteiraScreen({super.key, required this.controller, required this.mascotController});

  final PortfolioController controller;

  /// Drives [PortfolioNotConnectedCard]'s pet hero in the zero-holdings
  /// state. No [PetSpeechBubbleAnchor] here, unlike Início's own
  /// `PortfolioNotConnectedCard`: `DashboardScreen._heroAnchor` is reserved
  /// for whichever one is visible while Início is the selected tab, and
  /// `IndexedStack` keeps every tab's widgets mounted at once — reusing it
  /// here would register the same anchor's `GlobalKey` on two widgets
  /// simultaneously. The AppBar's `_headerAnchor` already covers every
  /// non-Início tab as the companion's fallback anchor.
  final MascotController mascotController;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    if (controller.isLoading && controller.holdings.isEmpty && controller.error == null) {
      return const AppLoadingIndicator();
    }

    final hasPortfolio = controller.holdings.isNotEmpty;

    return RefreshIndicator(
      color: tokens.primary,
      backgroundColor: tokens.surfaceElevated,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translator.translate(AppStrings.carteiraScreenTitle),
                        style: TextStyle(color: tokens.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Translator.translate(AppStrings.carteiraScreenSubtitle),
                        style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                if (hasPortfolio) AddAssetIconButton(controller: controller),
              ],
            ),
            const SizedBox(height: 16),

            if (controller.error != null) ...[
              ErrorBanner(
                message: 'Não foi possível atualizar seus dados. Puxe para atualizar.',
                onRetry: controller.refresh,
              ),
              const SizedBox(height: 16),
            ],

            if (!hasPortfolio)
              PortfolioNotConnectedCard(mascotController: mascotController, controller: controller)
            else ...[
              _CarteiraSummaryHeader(controller: controller),
              const SizedBox(height: 16),
              WealthEvolutionBarCard(series: controller.monthlyWealth12m),
              const SizedBox(height: 16),
              AllocationDonutCard(allocation: controller.allocation, totalValue: controller.summary.currentValue),
              const SizedBox(height: 16),
              HoldingsSection(
                holdings: controller.holdings,
                totalPortfolioValue: controller.summary.currentValue,
                controller: controller,
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Patrimônio investido headline + "Lucro total"/"12M" pills — the canvas's
/// simpler Carteira-tab header, distinct from Início's fuller 2×2
/// [PortfolioKpiGrid] (patrimônio, lucro, proventos, rentabilidade). Reuses
/// the same real figures and the grid's exact label/pill copy rather than
/// introducing near-duplicate strings.
class _CarteiraSummaryHeader extends StatelessWidget {
  const _CarteiraSummaryHeader({required this.controller});

  final PortfolioController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final summary = controller.summary;
    final totalProfit = controller.totalProfit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translator.translate(AppStrings.homeKpiTotalWealthLabel),
          style: TextStyle(color: tokens.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
        const SizedBox(height: 4),
        Text(
          AppFormatters.currency(summary.currentValue),
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (totalProfit != null)
              _SummaryPill(
                label:
                    '${Translator.translate(AppStrings.homeKpiTotalProfitLabel)} · ${AppFormatters.currency(totalProfit)}',
                color: tokens.primary,
              ),
            _SummaryPill(
              label:
                  '${Translator.translate(AppStrings.homeKpiReturn12mPrefix)} · '
                  '${AppFormatters.percentPlain(controller.annualChangePercent)}',
              color: tokens.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
