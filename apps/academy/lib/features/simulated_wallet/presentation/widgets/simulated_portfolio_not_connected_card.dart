import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/widgets/pet_mascot_widget.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// The empty-portfolio placeholder shown on the simulated Carteira until the
/// student places a first fictitious order — mirrors Wallet's real
/// `PortfolioNotConnectedCard` (`carteira` variant): the pet as a living
/// companion, a short title/body, and a single CTA into the order screen.
/// Replaces the wealth chart/donut/holdings sections entirely rather than
/// showing them alongside their own individually-empty states, so a student
/// who has never traded sees one clear invitation instead of three blank
/// widgets stacked on top of each other.
class SimulatedPortfolioNotConnectedCard extends StatelessWidget {
  const SimulatedPortfolioNotConnectedCard({super.key, required this.mascotController, required this.onAddAsset});

  final MascotController mascotController;
  final VoidCallback onAddAsset;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: PetMascotWidget(controller: mascotController, size: 120, interactive: false)),
        const SizedBox(height: 18),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Column(
              children: [
                Text(
                  Translator.translate(AppStrings.simulatedWalletEmptyStateTitle),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  Translator.translate(AppStrings.simulatedWalletEmptyStateBody),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        GameButton(
          label: Translator.translate(AppStrings.simulatedWalletEmptyStateCta),
          icon: Icons.arrow_forward,
          iconTrailing: true,
          gradientColors: const [AppColors.neonViolet, AppColors.neonCyan],
          height: 52,
          onPressed: onAddAsset,
        ),
      ],
    );
  }
}
