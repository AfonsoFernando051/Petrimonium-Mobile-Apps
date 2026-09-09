import 'package:flutter/material.dart';
import 'game_button.dart';

/// Secondary CTA for "Sign in with Google" — same [GameButton] chrome as the
/// primary email/password buttons, but a neutral gray fill (instead of the
/// brand accent) so it reads as an alternative, not the main action. [label]
/// is supplied by the caller so this widget carries no string catalog of
/// its own.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: label,
      icon: Icons.g_mobiledata,
      onPressed: onPressed,
      isLoading: isLoading,
      color: Colors.blueGrey.shade700,
    );
  }
}
