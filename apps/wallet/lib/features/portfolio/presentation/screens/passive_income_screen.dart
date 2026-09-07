import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_colors.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/formatters.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/app_loading_indicator.dart';
import 'package:petrimonium/core/widgets/layer_chip.dart';
import 'package:petrimonium/features/portfolio/domain/entities/dividend_event.dart';
import 'package:petrimonium/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/dividend_radar_section.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/passive_income_card.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/proventos_evolution_bar_card.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/shared/error_banner.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/shared/section_label.dart';

/// The "Proventos" (Passive Income) tab — its own dedicated home, no longer
/// folded into the Home dashboard. [controller] is owned and loaded by
/// `DashboardScreen` and shared across tabs. Leads with the real, confirmed
/// [DividendRadarSection], then the longer-range [PassiveIncomeCard]
/// estimate — confirmed data first, projection second.
class PassiveIncomeScreen extends StatefulWidget {
  const PassiveIncomeScreen({super.key, required this.controller});

  final PortfolioController controller;

  @override
  State<PassiveIncomeScreen> createState() => _PassiveIncomeScreenState();
}

class _PassiveIncomeScreenState extends State<PassiveIncomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadDividendRadarIfNeeded();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      widget.controller.refresh(),
      widget.controller.refreshDividendRadar(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller.isLoading && controller.holdings.isEmpty && controller.error == null) {
      return const AppLoadingIndicator();
    }

    return RefreshIndicator(
      color: AppColors.neonCyan,
      backgroundColor: context.colors.surfaceElevated,
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Translator.translate(AppStrings.proventosTitle),
              style: TextStyle(color: context.colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              Translator.translate(AppStrings.proventosSubtitle),
              style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            if (controller.error != null) ...[
              ErrorBanner(onRetry: controller.refresh),
              const SizedBox(height: 12),
            ],

            _ReceivedHeadlineCard(radar: controller.dividendRadar),
            const SizedBox(height: 16),
            DividendRadarSection(
              isLoading: controller.isDividendRadarLoading,
              error: controller.dividendRadarError,
              radar: controller.dividendRadar,
              onRetry: controller.refreshDividendRadar,
            ),
            const SizedBox(height: 16),
            ProventosEvolutionBarCard(radar: controller.dividendRadar),
            const SizedBox(height: 16),
            const SectionLabel('RENDA PASSIVA (ESTIMATIVA)'),
            const SizedBox(height: 10),
            PassiveIncomeCard(estimate: controller.passiveIncome),
          ],
        ),
      ),
    );
  }
}

/// "Recebido nos últimos 12 meses" — a real sum of confirmed-paid events
/// ([DividendRadar.receivedInLast12Months]), not a projection. Contrast with
/// [PassiveIncomeCard] below it on this screen, which is deliberately a
/// forward-looking yield estimate — the two answer different questions and
/// are not redundant.
class _ReceivedHeadlineCard extends StatelessWidget {
  const _ReceivedHeadlineCard({required this.radar});

  final DividendRadar radar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
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
          const LayerChip(layer: DataLayer.calculation, label: 'CÁLCULO DETERMINÍSTICO'),
          const SizedBox(height: 12),
          Text(
            AppFormatters.currency(radar.receivedInLast12Months()),
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Translator.translate(AppStrings.proventosReceivedLabel),
            style: TextStyle(color: tokens.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
