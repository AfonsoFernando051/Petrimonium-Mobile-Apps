import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';

/// Mandatory, always-visible reminder that every number on this screen is
/// virtual: no real order is ever executed, there is no connection to any
/// broker/bank/exchange/B3, and nothing here is financial advice. Shown on
/// every screen of the simulated wallet — never collapsible, never
/// dismissible, per the product rule that this must always be explicit.
///
/// Watches [Translator.languageNotifier] itself rather than trusting an
/// ancestor to rebuild it. Both call sites instantiate it as `const`, and a
/// const widget is canonicalised — Flutter sees the identical instance on the
/// next build and skips it. That left a user who switched to English still
/// reading the Portuguese disclaimer on the wallet screen. Of every string in
/// the product, this is the one that must not be stale.
class SimulationDisclaimerBanner extends StatelessWidget {
  const SimulationDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: tokens.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: tokens.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, size: 18, color: tokens.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: Translator.languageNotifier,
              builder: (context, _, _) => Text(
                Translator.translate(AppStrings.simulatedWalletDisclaimer),
                style: AppTextStyles.caption.copyWith(color: tokens.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
