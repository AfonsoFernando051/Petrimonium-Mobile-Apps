import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// A neutral product palette used only by this package's own tests.
///
/// It exists so the shared widgets are tested against *a* Petrimonium theme
/// rather than against Academy's or Wallet's in particular. If a widget only
/// renders correctly with one product's specific colors, that is a bug in the
/// widget, and testing against these deliberately unbranded values is what
/// catches it.
abstract final class TestPalette {
  static final AppColorTokens dark = AppColorTokens(
    backgroundPrimary: const Color(0xFF101014),
    backgroundSecondary: const Color(0xFF16161C),
    surface: const Color(0xFF101014),
    surfaceElevated: const Color(0xFF1D1D26),
    surfaceMuted: Colors.black.withValues(alpha: 0.24),
    textPrimary: Colors.white,
    textSecondary: const Color(0xFFCBCDD8),
    textTertiary: Colors.white54,
    border: Colors.white.withValues(alpha: 0.12),
    borderStrong: Colors.white.withValues(alpha: 0.24),
    divider: Colors.white24,
    primary: const Color(0xFF4DA6FF),
    primaryContainer: const Color(0x294DA6FF),
    secondary: const Color(0xFFB39DFF),
    mentor: const Color(0xFFB39DFF),
    success: const Color(0xFF00C878),
    warning: const Color(0xFFFFAB40),
    error: const Color(0xFFFF5C7A),
    info: const Color(0xFF2979FF),
    chartPositive: const Color(0xFF00C878),
    chartNegative: const Color(0xFFFF5C7A),
    chartNeutral: const Color(0xFFCBCDD8),
    overlay: Colors.black.withValues(alpha: 0.5),
    shadow: Colors.black.withValues(alpha: 0.4),
  );

  static final AppColorTokens light = dark.copyWith(
    backgroundPrimary: const Color(0xFFF7F7FC),
    backgroundSecondary: const Color(0xFFEEF0F6),
    surface: const Color(0xFFFCFCFE),
    surfaceElevated: const Color(0xFFFFFFFF),
    surfaceMuted: const Color(0xFFECEEF6),
    textPrimary: const Color(0xFF1B1C29),
    textSecondary: const Color(0xFF5B5E72),
    textTertiary: const Color(0xFF9296AA),
    border: const Color(0xFFE3E5EF),
    borderStrong: const Color(0xFFD2D6E4),
    divider: const Color(0xFFEAEBF2),
    overlay: Colors.black.withValues(alpha: 0.32),
    shadow: Colors.black.withValues(alpha: 0.08),
  );

  static const PetrimoniumBrandAccents accents = PetrimoniumBrandAccents(
    gradient: [Color(0xFF6A5BFF), Color(0xFFFF4D94)],
    accent: Color(0xFF4DA6FF),
    accentDeep: Color(0xFF3B2FBF),
    mentorGlow: Color(0xFFB39DFF),
    highlight: Color(0xFFFFD54F),
  );
}

/// The theme every widget test in this package renders against.
abstract final class TestTheme {
  static ThemeData get dark =>
      PetrimoniumTheme.build(brightness: Brightness.dark, colors: TestPalette.dark, accents: TestPalette.accents);

  static ThemeData get light =>
      PetrimoniumTheme.build(brightness: Brightness.light, colors: TestPalette.light, accents: TestPalette.accents);
}
