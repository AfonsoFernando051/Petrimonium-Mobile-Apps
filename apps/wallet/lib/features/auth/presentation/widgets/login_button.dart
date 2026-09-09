import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const LoginButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: Translator.translate(AppStrings.loginButton),
      icon: Icons.arrow_forward,
      iconTrailing: true,
      onPressed: onPressed,
      isLoading: isLoading,
      // No explicit color: GameButton's default (`context.colors.primary`,
      // emerald here) is the Wallet brand color, same as SignupActionButton's,
      // so Login and Cadastro (now on the same toggled screen) match.
    );
  }
}
