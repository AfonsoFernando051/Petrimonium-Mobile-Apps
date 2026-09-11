import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/utils/friendly_error_message.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/widgets/shared/section_label.dart';

/// One row per purchase lot, most recent first — ported from the old
/// `AssetDetailsSheet` as part of consolidating asset details into one
/// canonical, full-screen implementation. Only rendered for a real
/// [Holding] (with lots), same constraint as [AssetValuationChartCard].
///
/// Each row can edit or delete its own lot. [onLotChanged] fires after either
/// succeeds — the caller (`AssetDetailsScreen`) uses it to pop back to the
/// holdings list rather than keep showing its now-stale [holding] snapshot.
class PurchaseHistoryCard extends StatelessWidget {
  const PurchaseHistoryCard({super.key, required this.holding, required this.controller, required this.onLotChanged});

  final Holding holding;
  final PortfolioController controller;
  final VoidCallback onLotChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;

    return GlassCard(
      backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.55 : 0.94),
      borderColor: tokens.border,
      borderRadius: 18,
      borderWidth: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('HISTÓRICO DE COMPRAS'),
            const SizedBox(height: 8),
            for (final lot in holding.lots.reversed)
              _LotTile(lot: lot, controller: controller, onLotChanged: onLotChanged),
          ],
        ),
      ),
    );
  }
}

class _LotTile extends StatelessWidget {
  const _LotTile({required this.lot, required this.controller, required this.onLotChanged});

  final InvestmentLot lot;
  final PortfolioController controller;
  final VoidCallback onLotChanged;

  Future<void> _handleEdit(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddAssetScreen(controller: controller, editingLot: lot),
      ),
    );
    if (changed == true) onLotChanged();
  }

  Future<void> _handleDelete(BuildContext context) async {
    final tokens = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tokens.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          Translator.translate(AppStrings.deleteAssetConfirmTitle),
          style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          Translator.translate(AppStrings.deleteAssetConfirmMessage),
          style: TextStyle(color: tokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(Translator.translate(AppStrings.cancelButton), style: TextStyle(color: tokens.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(Translator.translate(AppStrings.deleteAssetConfirmCta), style: TextStyle(color: tokens.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await DI.investmentRepository.deleteInvestment(lot.id);
      await controller.refresh();
      if (context.mounted) {
        GameSnack.showWithHaptic(context, Translator.translate(AppStrings.deleteAssetSuccessSnack), isSuccess: true);
        onLotChanged();
      }
    } catch (e) {
      if (context.mounted) {
        GameSnack.show(
          context,
          '${Translator.translate(AppStrings.deleteAssetFailedSnack)} ${friendlyErrorMessage(e)}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.shopping_cart_outlined, size: 14, color: tokens.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppFormatters.date(lot.purchaseDate),
              style: TextStyle(color: tokens.textSecondary, fontSize: 11),
            ),
          ),
          Text(
            '${lot.quantity.toStringAsFixed(lot.quantity.truncateToDouble() == lot.quantity ? 0 : 2)} un · ${AppFormatters.currency(lot.purchasePrice)}',
            style: TextStyle(color: tokens.textPrimary, fontSize: 11),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert, size: 16, color: tokens.textSecondary),
            onSelected: (value) {
              if (value == 'edit') _handleEdit(context);
              if (value == 'delete') _handleDelete(context);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(Translator.translate(AppStrings.editAssetAction))),
              PopupMenuItem(value: 'delete', child: Text(Translator.translate(AppStrings.deleteAssetAction))),
            ],
          ),
        ],
      ),
    );
  }
}
