import 'package:flutter/material.dart';

import 'brand_accents.dart';

/// Centralized semantic design tokens. Every screen/widget should read
/// intent through these (via `context.colors`) instead of a literal color —
/// the same call site then resolves to the right value under Light, Dark,
/// or System, with no per-widget theme branching required.
///
/// The theme-invariant neon/gold brand accents are intentionally NOT
/// re-themed here: pet auras, achievement glow and gamification highlights
/// are meant to read as the same brand accent in both themes, only the
/// surfaces/backgrounds/text around them adapt. Those accents live in
/// [PetrimoniumBrandAccents], which each product supplies.
///
/// This class carries only the *shape* of the palette. Each product owns its
/// own Light/Dark values and passes them to [PetrimoniumTheme.build], which
/// is what lets Academy, Wallet and Health look related without looking
/// identical.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.mentor,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.chartPositive,
    required this.chartNegative,
    required this.chartNeutral,
    required this.overlay,
    required this.shadow,
  });

  /// Scaffold / screen base background.
  final Color backgroundPrimary;

  /// Secondary background surface (bottom nav, section backdrops).
  final Color backgroundSecondary;

  /// Base card/panel surface.
  final Color surface;

  /// Elevated surface — dialogs, sheets, snackbars, popovers.
  final Color surfaceElevated;

  /// Recessed/quiet surface — disabled cards, locked states, inline
  /// highlight backgrounds that need to sit *below* [surface] rather than
  /// above it.
  final Color surfaceMuted;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Neutral border for generic surfaces (not the colorful per-feature
  /// accent borders, which stay theme-invariant — see
  /// [PetrimoniumBrandAccents]).
  final Color border;

  /// A more visible neutral border for elevated/active surfaces that need
  /// to read as a step up from [border] without reaching for a full accent
  /// color.
  final Color borderStrong;
  final Color divider;

  final Color primary;
  final Color primaryContainer;
  final Color secondary;

  /// The Mentor's interpretation-layer accent (lilac). Deliberately the one
  /// color kept identical to Petrimonium-Wallet's token of the same name —
  /// it's how the Mentor reads as the same entity across both apps. Use this
  /// (not [secondary] or a raw brand accent) for anything that
  /// represents "this is the Mentor/AI interpretation", per the data /
  /// calculation / interpretation layer guardrail.
  final Color mentor;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  final Color chartPositive;
  final Color chartNegative;
  final Color chartNeutral;

  /// Modal/scrim overlay drawn behind dialogs and bottom sheets.
  final Color overlay;

  /// Plain elevation shadow (colored glow shadows keep using brand accents
  /// directly, e.g. `context.brand.accent.withValues(alpha: ...)`).
  final Color shadow;

  @override
  AppColorTokens copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? borderStrong,
    Color? divider,
    Color? primary,
    Color? primaryContainer,
    Color? secondary,
    Color? mentor,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? chartPositive,
    Color? chartNegative,
    Color? chartNeutral,
    Color? overlay,
    Color? shadow,
  }) {
    return AppColorTokens(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      mentor: mentor ?? this.mentor,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      chartPositive: chartPositive ?? this.chartPositive,
      chartNegative: chartNegative ?? this.chartNegative,
      chartNeutral: chartNeutral ?? this.chartNeutral,
      overlay: overlay ?? this.overlay,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      backgroundPrimary: Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary: Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      mentor: Color.lerp(mentor, other.mentor, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      chartPositive: Color.lerp(chartPositive, other.chartPositive, t)!,
      chartNegative: Color.lerp(chartNegative, other.chartNegative, t)!,
      chartNeutral: Color.lerp(chartNeutral, other.chartNeutral, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Ergonomic access: `context.colors.textPrimary` instead of
/// `Theme.of(context).extension<AppColorTokens>()!.textPrimary`.
extension AppThemeContextX on BuildContext {
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;

  /// The product's theme-invariant brand accents. See
  /// [PetrimoniumBrandAccents].
  PetrimoniumBrandAccents get brand => Theme.of(this).extension<PetrimoniumBrandAccents>()!;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
