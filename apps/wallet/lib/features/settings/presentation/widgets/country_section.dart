import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_wallet/core/preferences/country_preference.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';

/// Settings → País: BR/PT. Mesma anatomia da [LanguageSection]; a diferença é
/// que nenhuma opção vem seleccionada enquanto a conta não escolher.
class CountrySection extends StatelessWidget {
  const CountrySection({super.key, required this.sectionLabel, required this.onCountrySelected});

  final Widget Function(String label) sectionLabel;
  final ValueChanged<String> onCountrySelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final countries = [
      (code: 'BR', label: Translator.translate(AppStrings.countryBrazil), flag: '🇧🇷'),
      (code: 'PT', label: Translator.translate(AppStrings.countryPortugal), flag: '🇵🇹'),
    ];

    return ValueListenableBuilder<String?>(
      valueListenable: CountryPreference.notifier,
      builder: (context, selected, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionLabel(Translator.translate(AppStrings.countrySectionTitle).toUpperCase()),
            GlassCard(
              backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.6 : 0.94),
              // Contorno neutro e raio 18, como no artboard `SettingsWallet`.
              borderColor: tokens.textPrimary.withValues(alpha: 0.12),
              borderRadius: AppRadii.lg + 2,
              borderWidth: 1,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.lg + 2),
                child: Column(
                  children: [
                    for (var i = 0; i < countries.length; i++)
                      OptionRow(
                        leading: countries[i].flag,
                        label: countries[i].label,
                        selected: selected == countries[i].code,
                        onTap: () => onCountrySelected(countries[i].code),
                        showDivider: i < countries.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
