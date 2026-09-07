import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_colors.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium/core/utils/translator.dart';

/// Settings → "Companheiro": current pet name + a rename shortcut.
class CompanionSection extends StatelessWidget {
  const CompanionSection({super.key, required this.sectionLabel, required this.petName, required this.onRename});

  final Widget Function(String label) sectionLabel;
  final String? petName;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(Translator.translate(AppStrings.companionSectionTitle).toUpperCase()),
        GlassCard(
          backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.6 : 0.94),
          borderColor: AppColors.neonPink.withValues(alpha: 0.3),
          borderRadius: AppRadii.xl,
          borderWidth: 1,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.pets, color: AppColors.neonPink, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translator.translate(AppStrings.renamePetLabel),
                      style: AppTextStyles.label.copyWith(color: tokens.textSecondary),
                    ),
                    Text(
                      (petName?.isNotEmpty ?? false) ? petName! : '—',
                      style: AppTextStyles.title.copyWith(color: tokens.textPrimary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onRename,
                child: Text(
                  Translator.translate(AppStrings.renamePetButton),
                  style: const TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
