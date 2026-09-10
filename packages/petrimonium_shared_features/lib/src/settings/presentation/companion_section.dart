import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Settings → "Companheiro": current pet name + a rename shortcut.
///
/// Copy arrives as parameters — see [PrivacySection] for why. So does
/// [accentColor], and for the same reason: the field this section used to read
/// (`AppColors.neonPink`) is hot pink in Academy and emerald in Wallet. Baking
/// either one in would silently re-skin the other product.
class CompanionSection extends StatelessWidget {
  const CompanionSection({
    super.key,
    required this.sectionLabel,
    required this.sectionTitle,
    required this.renamePetLabel,
    required this.renamePetButtonLabel,
    required this.accentColor,
    required this.petName,
    required this.onRename,
  });

  final Widget Function(String label) sectionLabel;
  final String sectionTitle;
  final String renamePetLabel;
  final String renamePetButtonLabel;

  /// This section's own accent — the product's, not a shared one.
  final Color accentColor;
  final String? petName;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(sectionTitle.toUpperCase()),
        GlassCard(
          backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.6 : 0.94),
          borderColor: accentColor.withValues(alpha: 0.3),
          borderRadius: AppRadii.xl,
          borderWidth: 1,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.pets, color: accentColor, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(renamePetLabel, style: AppTextStyles.label.copyWith(color: tokens.textSecondary)),
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
                  renamePetButtonLabel,
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
