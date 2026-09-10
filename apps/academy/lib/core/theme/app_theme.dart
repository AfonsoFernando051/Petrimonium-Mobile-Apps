import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

import 'package:petrimonium_academy/core/theme/app_palette.dart';

/// Academy's two `ThemeData` instances. `MaterialApp` is given both
/// (`theme`/`darkTheme`) plus a `themeMode`, so Flutter — not app code —
/// decides which one is active; every screen then reads colors through
/// `context.colors` (the `AppColorTokens` extension registered below)
/// instead of branching on brightness itself.
///
/// The structure of the theme lives in `petrimonium_ui`; only the values are
/// Academy's. See [AppPalette].
class AppTheme {
  AppTheme._();

  static ThemeData get light =>
      PetrimoniumTheme.build(brightness: Brightness.light, colors: AppPalette.light, accents: AppPalette.accents);

  static ThemeData get dark =>
      PetrimoniumTheme.build(brightness: Brightness.dark, colors: AppPalette.dark, accents: AppPalette.accents);
}
