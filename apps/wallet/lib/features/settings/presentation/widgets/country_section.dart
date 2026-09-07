import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_colors.dart';
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
              borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
              borderRadius: AppRadii.xl,
              borderWidth: 1,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: countries.map((country) {
                  final isSelected = selected == country.code;
                  return InkWell(
                    onTap: () => onCountrySelected(country.code),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                      child: Row(
                        children: [
                          Text(country.flag, style: AppTextStyles.headline),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              country.label,
                              style: AppTextStyles.title.copyWith(
                                color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle, color: tokens.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
