import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

import 'package:petrimonium/core/constants/app_colors.dart';

/// Academy's own values for the shared token shapes in `petrimonium_ui`.
///
/// These moved out of the package deliberately: the token *shape* is shared
/// so every product themes the same way, but the values are Academy's
/// identity (cosmic dark, cyan/violet accents) and must not leak into Wallet
/// or Health. Wallet has the file of the same name with emerald values.
abstract final class AppPalette {
  static final AppColorTokens dark = AppColorTokens(
    backgroundPrimary: AppColors.spaceDark,
    backgroundSecondary: AppColors.backgroundDark,
    surface: AppColors.spaceDark,
    surfaceElevated: AppColors.spaceBlue,
    surfaceMuted: Colors.black.withValues(alpha: 0.24),
    textPrimary: Colors.white,
    textSecondary: AppColors.subtleText,
    textTertiary: Colors.white54,
    border: Colors.white.withValues(alpha: 0.12),
    borderStrong: Colors.white.withValues(alpha: 0.24),
    divider: Colors.white24,
    primary: AppColors.neonCyan,
    primaryContainer: AppColors.neonCyan.withValues(alpha: 0.16),
    secondary: AppColors.neonPurple,
    mentor: AppColors.neonPurple,
    success: AppColors.positiveGreen,
    warning: AppColors.warningAmber,
    error: AppColors.negativeRed,
    info: AppColors.neonBlue,
    chartPositive: AppColors.positiveGreen,
    chartNegative: AppColors.negativeRed,
    chartNeutral: AppColors.subtleText,
    overlay: Colors.black.withValues(alpha: 0.5),
    shadow: Colors.black.withValues(alpha: 0.4),
  );

  // Warm-pearl / soft-lavender light palette — deliberately not a plain
  // inversion of dark. Backgrounds carry a faint cool-lavender tint instead
  // of pure #FFFFFF (brief: "avoid pure white everywhere"); accent tokens
  // are darkened shades of the brand neon hues so text/icons/fills clear
  // WCAG AA on white while still reading as the same brand family.
  static final AppColorTokens light = AppColorTokens(
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
    primary: const Color(0xFF0089A0),
    primaryContainer: const Color(0xFFDDF5F8),
    secondary: const Color(0xFF6B4FD6),
    mentor: const Color(0xFF6B4FD6),
    success: const Color(0xFF1E9E64),
    warning: const Color(0xFFAD6A00),
    error: const Color(0xFFD32F4B),
    info: const Color(0xFF1E63D9),
    chartPositive: const Color(0xFF1E9E64),
    chartNegative: const Color(0xFFD32F4B),
    chartNeutral: const Color(0xFF9296AA),
    overlay: Colors.black.withValues(alpha: 0.32),
    shadow: Colors.black.withValues(alpha: 0.08),
  );

  /// Theme-invariant accents. Same values the widgets previously read
  /// straight off [AppColors]; they are passed to the shared theme now so
  /// that widgets living in `petrimonium_ui` can resolve them without
  /// importing anything Academy-specific.
  static const PetrimoniumBrandAccents accents = PetrimoniumBrandAccents(
    gradient: AppColors.brandGradient,
    accent: AppColors.neonCyan,
    accentDeep: AppColors.neonViolet,
    mentorGlow: AppColors.neonPurple,
    highlight: AppColors.goldenBorder,
  );
}
