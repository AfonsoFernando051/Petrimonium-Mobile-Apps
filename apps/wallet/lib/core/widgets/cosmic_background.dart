import 'package:flutter/material.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';

/// The app's shared background — a flat top-to-bottom gradient between
/// [AppColorTokens.backgroundPrimary] and [AppColorTokens.backgroundSecondary]
/// (dark theme: petrol-green #08110E → #0D1A16), matching the Wallet design
/// system exactly ("Fundo verde-petróleo escuro", Notion — Petrimonium
/// Wallet Onboarding Design). No nebula image, starfield, drift animation,
/// or ambient glow: those belonged to an earlier, more decorative direction
/// this app no longer follows — Wallet's real mockups show a static,
/// uniform background behind every screen, in keeping with its "menos
/// decorativo" density-over-atmosphere identity.
class CosmicBackground extends StatelessWidget {
  const CosmicBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.backgroundPrimary, tokens.backgroundSecondary],
        ),
      ),
      child: child,
    );
  }
}
