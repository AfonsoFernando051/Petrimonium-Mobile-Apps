import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/core/widgets/cosmic_background.dart';
import 'package:petrimonium_wallet/core/widgets/layer_chip.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/allocation_donut_card.dart';

/// A one-time guided reading shown right after the very first asset lands
/// in an otherwise-empty portfolio (FR-WAL-006/007) — the moment `Overview`
/// used to jump straight from [PortfolioNotConnectedCard] to the full
/// dashboard with no in-between read of "what did I just build".
///
/// Deliberately narrower than the normal dashboard: no evolution/wealth-change
/// cards here, since a single just-registered lot has no history to explain
/// yet (PRD: "métricas sem histórico suficiente ficam ocultas"). Ends with a
/// single CTA into the normal, now-populated dashboard.
class FirstValueScreen extends StatelessWidget {
  const FirstValueScreen({super.key, required this.controller});

  final PortfolioController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  Translator.translate(AppStrings.firstValueTitle),
                  style: TextStyle(color: tokens.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  Translator.translate(AppStrings.firstValueIntro),
                  style: TextStyle(color: tokens.textSecondary, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),

                // ── Patrimônio total ─────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LayerChip(
                        layer: DataLayer.data,
                        label: '${Translator.translate(AppStrings.homeWealthDataChipLabel)} · brapi.dev, hoje $time',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppFormatters.currency(controller.summary.currentValue),
                        style: TextStyle(color: tokens.textPrimary, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('BRL', style: TextStyle(color: tokens.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Composição básica ────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Translator.translate(AppStrings.firstValueCompositionTitle),
                        style: TextStyle(
                          color: tokens.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final holding in controller.holdings) ...[
                        _HoldingRow(holding: holding),
                        if (holding != controller.holdings.last) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Alocação por classe ──────────────────────────
                AllocationDonutCard(allocation: controller.allocation, totalValue: controller.summary.currentValue),
                const SizedBox(height: 16),

                // ── Metodologia acessível ────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Translator.translate(AppStrings.firstValueMethodologyTitle),
                        style: TextStyle(
                          color: tokens.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Translator.translate(AppStrings.firstValueMethodologyBody),
                        style: TextStyle(color: tokens.textSecondary, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                GameButton(
                  label: Translator.translate(AppStrings.firstValueCta),
                  icon: Icons.arrow_forward,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '${holding.ticker} · ${holding.quantity.toStringAsFixed(holding.quantity.truncateToDouble() == holding.quantity ? 0 : 2)} un',
            style: TextStyle(color: tokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(AppFormatters.currency(holding.currentValue), style: TextStyle(color: tokens.textSecondary, fontSize: 13)),
      ],
    );
  }
}
