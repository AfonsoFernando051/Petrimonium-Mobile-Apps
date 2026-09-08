import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';

/// Settings → Language: pt/en/es picker. Reads [Translator.currentLanguage]
/// directly for the selected-state highlight — the parent screen already
/// rebuilds this section on every language change via its own
/// `Translator.languageNotifier` listener.
class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key, required this.sectionLabel, required this.onLanguageSelected});

  final Widget Function(String label) sectionLabel;
  final ValueChanged<String> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final languages = [
      (code: 'pt', label: Translator.translate(AppStrings.languagePt), flag: '🇧🇷'),
      (code: 'pt_PT', label: Translator.translate(AppStrings.languagePtPt), flag: '🇵🇹'),
      (code: 'en', label: Translator.translate(AppStrings.languageEn), flag: '🇺🇸'),
      (code: 'es', label: Translator.translate(AppStrings.languageEs), flag: '🇪🇸'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(Translator.translate(AppStrings.languageSectionTitle).toUpperCase()),
        GlassCard(
          backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.6 : 0.94),
          // Contorno neutro e raio 18, como no artboard `SettingsWallet`: as
          // secções não têm cor própria de acento na moldura.
          borderColor: tokens.textPrimary.withValues(alpha: 0.12),
          borderRadius: AppRadii.lg + 2,
          borderWidth: 1,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg + 2),
            child: Column(
              children: [
                for (var i = 0; i < languages.length; i++)
                  OptionRow(
                    leading: languages[i].flag,
                    label: languages[i].label,
                    selected: Translator.currentLanguage == languages[i].code,
                    onTap: () => onLanguageSelected(languages[i].code),
                    showDivider: i < languages.length - 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
