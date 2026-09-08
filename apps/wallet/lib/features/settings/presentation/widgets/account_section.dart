import 'package:flutter/material.dart';
import 'package:petrimonium_wallet/core/constants/app_strings.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';

/// Settings → Account: signed-in email + logout.
class AccountSection extends StatelessWidget {
  const AccountSection({
    super.key,
    required this.sectionLabel,
    required this.email,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final Widget Function(String label) sectionLabel;
  final String? email;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(Translator.translate(AppStrings.accountSectionTitle).toUpperCase()),
        GlassCard(
          backgroundColor: tokens.surface.withValues(alpha: context.isDarkMode ? 0.6 : 0.94),
          // Contorno neutro: o artboard `SettingsWallet` usa a mesma linha
          // esbatida dos outros cartões, não um rosa próprio da secção.
          borderColor: tokens.textPrimary.withValues(alpha: 0.12),
          borderRadius: AppRadii.lg + 2,
          borderWidth: 1,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (email != null) ...[
                Row(
                  children: [
                    Icon(Icons.person_outline, color: tokens.textSecondary, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(email!, style: AppTextStyles.bodyEmphasis.copyWith(color: tokens.textPrimary, fontWeight: FontWeight.normal)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Divider(color: tokens.divider),
                const SizedBox(height: AppSpacing.sm),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: Icon(Icons.logout, color: tokens.error, size: 17),
                  label: Text(
                    Translator.translate(AppStrings.logoutButton),
                    style: TextStyle(color: tokens.error, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: tokens.error, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Contorno tracejado e sem preenchimento: fica claramente
              // subordinado a Sair, para não se clicar nele por engano.
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Opacity(
                  opacity: 0.75,
                  child: DashedOutline(
                    color: tokens.error,
                    radius: AppRadii.md,
                    child: TextButton.icon(
                      onPressed: onDeleteAccount,
                      icon: Icon(Icons.delete_outline, color: tokens.error, size: 17),
                      label: Text(
                        Translator.translate(AppStrings.deleteAccountButton),
                        style: TextStyle(color: tokens.error, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
