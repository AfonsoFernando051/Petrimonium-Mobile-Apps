import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_colors.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_wallet/features/home/presentation/widgets/home_pet_hero.dart';
import 'package:petrimonium_wallet/features/investment/presentation/screens/investment_configuration_screen.dart';
import 'package:petrimonium_wallet/features/pet/presentation/mascot/controllers/mascot_controller.dart';

/// Home's placeholder when the user has no holdings yet — the app must stay
/// fully usable without a portfolio, so this replaces the wealth/holdings
/// sections instead of blocking Home. Leads with the Pet as a big, living
/// companion (see `HomePetHero`) rather than a small icon: "o PET deve ser
/// maior e aparecer mais no dashboard, nao ficar pequeno e discreto."
///
/// There is no real brokerage connection anywhere in this app yet (see
/// `docs/ECOSYSTEM.md`) — the manual-entry CTA opens
/// [InvestmentConfigurationScreen], the only way holdings ever get in today;
/// the B3 option is shown so the user knows it's coming, but only offers a
/// "coming soon" acknowledgement, not a real connection.
class PortfolioNotConnectedCard extends StatelessWidget {
  const PortfolioNotConnectedCard({super.key, required this.mascotController, this.anchor});

  final MascotController mascotController;
  final PetSpeechBubbleAnchor? anchor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompanionCaption(tokens: tokens),
        const SizedBox(height: 8),
        Center(
          child: HomePetHero(mascotController: mascotController, anchor: anchor, size: 168),
        ),
        const SizedBox(height: 16),
        GlassCard(
          backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.5 : 0.94),
          borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
          borderRadius: 24,
          borderWidth: 1,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  Translator.translate(AppStrings.portfolioNotConnectedTitle),
                  style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  Translator.translate(AppStrings.portfolioNotConnectedBody),
                  style: TextStyle(color: tokens.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                GameButton(
                  label: Translator.translate(AppStrings.connectAssetsManualCta),
                  icon: Icons.edit_outlined,
                  height: 52,
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const InvestmentConfigurationScreen()));
                  },
                ),
                const SizedBox(height: 10),
                _B3ConnectRow(tokens: tokens),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The companion's own speech-bubble-style line above the big pet — static
/// copy here (not routed through `PetCompanionController`'s message queue)
/// since it's this specific empty state's framing, always true whenever
/// it's shown, not a contextual nudge that needs cooldown/priority rules.
class _CompanionCaption extends StatelessWidget {
  const _CompanionCaption({required this.tokens});

  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.neonCyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4)),
        ),
        child: Text(
          Translator.translate(AppStrings.portfolioNotConnectedPetCaption),
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.textPrimary, fontSize: 13.5, height: 1.4),
        ),
      ),
    );
  }
}

/// The B3-sync option — always visible so the user knows a second, automatic
/// way of bringing in assets is planned, but there is no real integration to
/// open yet (see class doc), so tapping only acknowledges that with a
/// "coming soon" snack instead of navigating anywhere.
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
