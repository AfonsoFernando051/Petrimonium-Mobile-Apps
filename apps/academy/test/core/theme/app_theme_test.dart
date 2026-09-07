import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/theme/app_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light has Brightness.light and the AppPalette.light extension', () {
      final theme = AppTheme.light;

      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppColorTokens>(), AppPalette.light);
      expect(theme.scaffoldBackgroundColor, AppPalette.light.backgroundPrimary);
    });

    test('dark has Brightness.dark and the AppPalette.dark extension', () {
      final theme = AppTheme.dark;

      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<AppColorTokens>(), AppPalette.dark);
      expect(theme.scaffoldBackgroundColor, AppPalette.dark.backgroundPrimary);
    });

    test('colorScheme brightness matches the theme brightness', () {
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });
  });
}
