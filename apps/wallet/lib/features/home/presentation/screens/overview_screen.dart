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
import 'package:petrimonium_wallet/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/models/investment_type_display.dart';
import 'package:petrimonium_wallet/features/portfolio/domain/entities/wealth_change_breakdown.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/allocation_donut_card.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/holdings_section.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/wealth_evolution_card.dart';

/// Wallet's "Início" — the unified patrimônio + Mentor screen, absorbing
/// what used to be a separate Carteira tab ("Home unifica patrimônio
/// total... sem uma aba 'Carteira' redundante" per the Wallet design
/// system). Shows: a greeting, the Mentor's one interpretation for the
/// session, total wealth (labeled as data — source/timestamp always shown),
/// a real valorização/aportes/rendimentos breakdown for the trailing 30
/// days (`PortfolioController.wealthChange30d`, computed client-side from
/// real lot/dividend data), and holdings grouped by category.
///
/// No own `Scaffold`/`AppBar`/background — embedded directly in
/// `DashboardScreen`'s shared chrome.
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    required this.controller,
    required this.onOpenMentor,
    required this.mascotController,
    this.heroAnchor,
  });

  final PortfolioController controller;

  /// Opens the Mentor tab, optionally resuming a specific conversation
  /// (Home's Mentor card's "Por que estou vendo isto?") — `null` opens a
  /// blank chat.
  final ValueChanged<int?> onOpenMentor;

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
              PortfolioNotConnectedCard(mascotController: widget.mascotController, anchor: widget.heroAnchor)
            else ...[
              _WealthHeroCard(controller: controller),
              const SizedBox(height: 16),
              AllocationDonutCard(allocation: controller.allocation, totalValue: controller.summary.currentValue),
              const SizedBox(height: 16),
              WealthEvolutionCard(controller: controller),
              const SizedBox(height: 16),
              _WealthChangeCard(breakdown: controller.wealthChange30d),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Translator.translate(AppStrings.homeHoldingsSectionTitle),
                    style: TextStyle(
                      color: context.colors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  _AddAssetButton(controller: controller),
                ],
              ),
              const SizedBox(height: 8),
              HoldingsSection(holdings: controller.holdings, totalPortfolioValue: controller.summary.currentValue),
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

class _WealthHeroCard extends StatelessWidget {
  const _WealthHeroCard({required this.controller});

  final PortfolioController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final types = controller.holdings.map((Holding h) => h.type).toSet().map((type) => type.label).join(', ');

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
            Translator.translate(AppStrings.homeWealthSectionTitle),
            style: TextStyle(color: tokens.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
          const SizedBox(height: 12),
          LayerChip(
            layer: DataLayer.data,
            label: '${Translator.translate(AppStrings.homeWealthDataChipLabel)} · brapi.dev, hoje $time',
          ),
          const SizedBox(height: 12),
          Text(
            AppFormatters.currency(controller.summary.currentValue),
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'BRL · ${Translator.translate(AppStrings.homeWealthScopePrefix)}: $types',
            style: TextStyle(color: tokens.textSecondary, fontSize: 12),
          ),
        ],
      ),
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

/// Opens [AddAssetScreen] to add another asset once the portfolio already
/// has at least one — [PortfolioNotConnectedCard] covers the zero-holdings
/// case with its own full-width CTA into the Academy-style onboarding
/// wizard (`InvestmentConfigurationScreen`), so this only needs to exist
/// here in the "Meus ativos" section header, opening the plain Wallet
/// single-asset screen instead.
class _AddAssetButton extends StatelessWidget {
  const _AddAssetButton({required this.controller});

  final PortfolioController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddAssetScreen(controller: controller)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 15, color: tokens.primary),
            const SizedBox(width: 4),
            Text(
              Translator.translate(AppStrings.homeAddAssetLabel),
              style: TextStyle(color: tokens.primary, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
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
