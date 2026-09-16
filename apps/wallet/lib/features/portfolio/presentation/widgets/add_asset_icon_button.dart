import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/investment/presentation/screens/add_asset_screen.dart';
import 'package:petrimonium_wallet/features/portfolio/presentation/controllers/portfolio_controller.dart';

/// The small "+ Adicionar" link that opens [AddAssetScreen] to add another
/// asset once the portfolio already has at least one — used in a section
/// header on both Início ("Meus ativos") and Carteira ("Seus investimentos").
/// [PortfolioNotConnectedCard] covers the zero-holdings case with its own
/// full-width CTA into that same [AddAssetScreen], so this only needs to
/// exist in these section headers.
class AddAssetIconButton extends StatelessWidget {
  const AddAssetIconButton({super.key, required this.controller});

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
