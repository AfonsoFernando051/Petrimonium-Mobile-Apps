import 'package:flutter/material.dart';
import 'game_button.dart';

/// Secondary CTA for "Sign in with Google" — same [GameButton] gradient/glow
/// chrome as the primary login/signup CTA, but a neutral gray gradient
/// (instead of the brand accent) so it reads as an alternative, not the main
/// action. No pulse — that's reserved for the single primary CTA on the
/// screen. [label] is supplied by the caller so this widget carries no
/// string catalog of its own.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.label, this.onPressed, this.isLoading = false});

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
      gradientColors: [Colors.blueGrey.shade600, Colors.blueGrey.shade800],
    );
  }
}
