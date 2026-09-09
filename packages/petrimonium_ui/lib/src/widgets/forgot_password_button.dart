import 'package:flutter/material.dart';
import '../tokens/app_color_tokens.dart';

/// An underlined text link, typically "Forgot your password?" under a login
/// form. Carries no route of its own — [onTap] is the caller's navigation to
/// its own forgot-password screen, and [label] is the caller's copy.
class ForgotPasswordButton extends StatelessWidget {
  const ForgotPasswordButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textSecondary = context.colors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: textSecondary,
          decoration: TextDecoration.underline,
          decorationColor: textSecondary,
        ),
      ),
    );
  }
}
