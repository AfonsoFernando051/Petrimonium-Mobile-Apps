import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/app_color_tokens.dart';
import '../tokens/app_radii.dart';
import '../tokens/brand_accents.dart';

/// Builds a `ThemeData` from a product's own tokens.
///
/// This is the whole of the shared theming contract: the *structure* of a
/// Petrimonium theme (which Material surfaces map to which semantic token,
/// how the type scale is built, what the snackbar/dialog/nav-bar chrome
/// looks like) lives here, and every product supplies its own colors. That
/// is what "same family, not identical" means in practice — Academy, Wallet
/// and Health share this builder and differ only in what they pass in.
///
/// It is deliberately NOT a switch on product. There is no `Product` enum
/// here and there must never be one: adding a fourth Petrimonium app should
/// require zero edits to this file.
///
/// Each app is expected to expose its own thin wrapper, e.g.
/// ```dart
/// class AppTheme {
///   static ThemeData get light => PetrimoniumTheme.build(
///         brightness: Brightness.light,
///         colors: AcademyPalette.light,
///         accents: AcademyPalette.accents,
///       );
/// }
/// ```
class PetrimoniumTheme {
  PetrimoniumTheme._();

  static ThemeData build({
    required Brightness brightness,
    required AppColorTokens colors,
    required PetrimoniumBrandAccents accents,
  }) {
    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final onPrimary = brightness == Brightness.dark ? Colors.black : Colors.white;
    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );
    final fieldRadius = BorderRadius.circular(AppRadii.md);

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: colors.backgroundPrimary,
      textTheme: textTheme,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: onPrimary,
        secondary: colors.secondary,
        onSecondary: Colors.white,
        error: colors.error,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      dividerColor: colors.divider,
      iconTheme: IconThemeData(color: colors.textSecondary),
      splashColor: colors.primary.withValues(alpha: 0.12),
      highlightColor: colors.primary.withValues(alpha: 0.06),
      // Flat, no-elevation chrome for inputs and CTAs — the structural half
      // of the shared visual language (spacing/radius/weight), independent
      // of each product's own colors. See `docs/MOBILE_ARCHITECTURE.md`.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: colors.border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: colors.error)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: colors.error, width: 1.4),
        ),
        hintStyle: GoogleFonts.outfit(color: colors.textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: GoogleFonts.outfit(color: colors.textPrimary, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.backgroundSecondary,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textTertiary,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      extensions: [colors, accents],
    );
  }
}
