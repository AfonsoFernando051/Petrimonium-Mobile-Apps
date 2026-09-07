import 'package:flutter/material.dart';

/// Raw brand palette. Surfaces/text/backgrounds should NOT be read from here
/// directly anymore — use `context.colors` (`AppColorTokens`, see
/// `core/theme/app_color_tokens.dart`), which resolves to the right value
/// for the active Light/Dark/System theme.
///
/// The neon/gold accents below are the exception: pet auras, achievement
/// glow and other gamification highlights are meant to read as the exact
/// same brand color in both themes (only what surrounds them adapts), so
/// they stay theme-invariant constants here rather than tokens.
class AppColors {
  AppColors._();

  // Petrol-green theme backgrounds — dark theme only; use context.colors for
  // anything that must also work in Light. Deliberately not the Academy's
  // cosmic dark: Wallet's design system replaces it to keep "learning" and
  // "real patrimony" visually distinct at a glance.
  static const Color spaceDark   = Color(0xFF08110E);
  static const Color spaceBlue   = Color(0xFF0D1A16);
  static const Color spacePurple = Color(0xFF102420); // mid petrol tone, for 3-stop gradients

  // Legacy compatibility
  static const Color backgroundLight  = Color(0xFF6A11CB);
  static const Color backgroundMedium = Color(0xFF2C5364);
  static const Color backgroundDark   = Color(0xFF0F2027);

  static const Color primaryButton = Colors.deepPurple;

  static final Color white10 = Colors.white.withValues(alpha: 0.1);
  static final Color white20 = Colors.white.withValues(alpha: 0.2);
  static const Color white54 = Colors.white54;
  static const Color white70 = Colors.white70;
  static const Color white   = Colors.white;

  // Emerald palette — primary brand colors. Replaces the Academy's
  // cyan/violet/pink identity with Wallet's emerald ("acento primário
  // verde-esmeralda ... substitui o roxo/magenta da Academy") — same field
  // names as Academy's AppColors (only the literals differ) so every screen
  // already reading these constants re-themes for free.
  static const Color neonCyan   = Color(0xFF3FE0B0); // emerald, bright — primary accent + "cálculo" layer
  static const Color neonPurple = Color(0xFFC5ABFF); // UNCHANGED — Mentor lilac, the one constant shared with Academy
  static const Color neonViolet = Color(0xFF0B7A5F); // emerald, deep
  static const Color neonBlue   = Color(0xFF2979FF);
  static const Color neonPink   = Color(0xFF3FE0B0); // emerald, bright
  static const Color goldenBorder = Color(0xFFFFD54F);

  /// The product's single strongest visual signature — progression, XP,
  /// rewards, primary CTAs, "this is the current step" states. Reused as a
  /// constant (rather than redefined per widget) so every gradient moment
  /// in the app reads as the same brand gesture.
  static const List<Color> brandGradient = [neonViolet, neonPink];

  // Semantic / state colors — themed, NOT generic Material defaults
  static const Color positiveGreen = Color(0xFF00E676); // neon green
  static const Color negativeRed   = Color(0xFFFF5C7A); // soft red — never a panic/alarm red
  static const Color warningAmber  = Color(0xFFFFAB40); // alert amber

  // Subdued text — better contrast than Colors.white70 on dark glass
  static const Color subtleText = Color(0xFFCBCDD8);
}
