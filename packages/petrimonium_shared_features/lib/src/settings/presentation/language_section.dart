import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Settings → Language: pt/en/es picker.
///
/// [selectedLanguage] drives the selected-state highlight; the parent screen
/// passes what its translator currently reports and already rebuilds this
/// section on every language change via its own `languageNotifier` listener.
///
/// Copy arrives as parameters — see [PrivacySection] for why. The codes and
/// flags do not: which languages the ecosystem offers is a shared fact, and a
/// product cannot quietly support a different set.
class LanguageSection extends StatelessWidget {
  const LanguageSection({
    super.key,
    required this.sectionLabel,
    required this.sectionTitle,
    required this.portugueseLabel,
    required this.europeanPortugueseLabel,
    required this.englishLabel,
    required this.spanishLabel,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  final Widget Function(String label) sectionLabel;
  final String sectionTitle;
  final String portugueseLabel;
  final String europeanPortugueseLabel;
  final String englishLabel;
  final String spanishLabel;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final languages = [
      (code: 'pt', label: portugueseLabel, flag: '🇧🇷'),
      (code: 'pt_PT', label: europeanPortugueseLabel, flag: '🇵🇹'),
      (code: 'en', label: englishLabel, flag: '🇺🇸'),
      (code: 'es', label: spanishLabel, flag: '🇪🇸'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(sectionTitle.toUpperCase()),
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
                    selected: selectedLanguage == languages[i].code,
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
