import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/controllers/simulated_wallet_controller.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/screens/place_simulated_order_screen.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/reset_simulated_wallet_dialog.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulated_allocation_donut_card.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulated_holdings_section.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulated_portfolio_not_connected_card.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulated_wallet_kpi_header.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulation_disclaimer_banner.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/wealth_evolution_bar_card.dart';

/// Academy's "Carteira" tab — a fictitious wallet with a virtual starting
/// balance, entirely separate from any real investment account. Never
/// imports from `features/portfolio` or `features/investment` (Wallet's real
/// domain); talks only to `SimulatedWalletController`/`SimulatedWalletRepository`
/// (backend `simulated_portfolio` context).
///
/// Mirrors Wallet's real `CarteiraScreen` layout — patrimônio header, wealth
/// evolution chart, allocation donut, holdings grouped by investment type —
/// so a student building a simulated portfolio "however they see fit" (any
/// ticker, any asset type) sees the same shape they'd get with a real one.
/// Like `CarteiraScreen`, it owns no `Scaffold`/`AppBar` of its own — this is
/// embedded directly in `DashboardScreen`'s shared chrome; its own in-body
/// header row carries the title/reset/add-asset actions instead.
class SimulatedWalletScreen extends StatefulWidget {
  const SimulatedWalletScreen({super.key, required this.controller, required this.mascotController});

  final SimulatedWalletController controller;

  /// Drives the pet shown by [SimulatedPortfolioNotConnectedCard] while the
  /// student hasn't placed a first simulated order yet — the same
  /// mascot/species Academy shows everywhere else, not a Wallet-style fixed
  /// species.
  final MascotController mascotController;

  @override
  State<SimulatedWalletScreen> createState() => _SimulatedWalletScreenState();
}

class _SimulatedWalletScreenState extends State<SimulatedWalletScreen> {
  @override
  void initState() {
    super.initState();
    // The load itself is triggered once by DashboardScreen (alongside
    // PortfolioController.loadAll()), not here — this tab is mounted
    // immediately by the shared IndexedStack even while another tab is
    // selected, and this widget may be rebuilt more than once while staying
    // mounted, so re-triggering the load from initState would race a load
    // already in flight. This listener just keeps the screen in sync with
    // whatever state the controller is already in.
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openNewOrder() async {
    unawaited(HapticFeedback.mediumImpact());
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlaceSimulatedOrderScreen(controller: widget.controller)));
  }

  Future<void> _confirmReset() async {
    final confirmed = await ResetSimulatedWalletDialog.show(context);
    if (!confirmed) return;

    unawaited(HapticFeedback.mediumImpact());
    final succeeded = await widget.controller.resetPortfolio();
    if (!mounted) return;

    if (succeeded) {
      GameSnack.show(context, Translator.translate(AppStrings.simulatedWalletResetSuccess), isSuccess: true);
    } else if (widget.controller.resetError != null) {
      GameSnack.show(context, widget.controller.resetError!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller.isLoading && controller.portfolio.positions.isEmpty && controller.error == null) {
      return const AppLoadingIndicator();
    }

    if (controller.error != null) {
      return ErrorStateView(
        retryLabel: Translator.translate(AppStrings.retryButtonLabel),
        title: Translator.translate(AppStrings.simulatedWalletTitle),
        message: controller.error!,
        onRetry: controller.loadPortfolio,
        style: ErrorStateStyle.card,
      );
    }

    final tokens = context.colors;
    final hasPortfolio = controller.portfolio.positions.isNotEmpty;

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
            _buildHeader(hasPortfolio: hasPortfolio),
            const SizedBox(height: 16),
            const SimulationDisclaimerBanner(),
            const SizedBox(height: 16),
            if (!hasPortfolio)
              SimulatedPortfolioNotConnectedCard(mascotController: widget.mascotController, onAddAsset: _openNewOrder)
            else ...[
              SimulatedWalletKpiHeader(
                totalPatrimony: controller.totalPositionsValue,
                totalProfit: controller.totalProfit,
                totalProfitPercent: controller.totalProfitPercent,
              ),
              const SizedBox(height: 16),
              WealthEvolutionBarCard(series: controller.monthlyWealth12m),
              const SizedBox(height: 16),
              SimulatedAllocationDonutCard(
                allocation: controller.allocation,
                totalValue: controller.totalPositionsValue,
              ),
              const SizedBox(height: 16),
              SimulatedHoldingsSection(
                holdings: controller.holdings,
                totalPortfolioValue: controller.totalPositionsValue,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required bool hasPortfolio}) {
    final tokens = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translator.translate(AppStrings.simulatedWalletTitle),
                style: TextStyle(color: tokens.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                Translator.translate(AppStrings.simulatedWalletHeaderSubtitle),
                style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.restart_alt, color: tokens.textSecondary),
          tooltip: Translator.translate(AppStrings.simulatedWalletResetAction),
          onPressed: widget.controller.isResetting ? null : _confirmReset,
        ),
        // Mirrors Wallet's real CarteiraScreen: once a portfolio exists, the
        // header carries the "add another asset" shortcut; before that, the
        // single CTA lives inside SimulatedPortfolioNotConnectedCard so
        // there's exactly one invitation to act, not two.
        if (hasPortfolio) _AddAssetIconButton(onTap: _openNewOrder),
      ],
    );
  }
}

/// The small "+ Adicionar" link that opens [PlaceSimulatedOrderScreen] —
/// mirrors Wallet's real `AddAssetIconButton` spot in the header row.
class _AddAssetIconButton extends StatelessWidget {
  const _AddAssetIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 18, color: tokens.primary),
            const SizedBox(width: 4),
            Text(
              Translator.translate(AppStrings.simulatedWalletAddAssetLabel),
              style: TextStyle(color: tokens.primary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
