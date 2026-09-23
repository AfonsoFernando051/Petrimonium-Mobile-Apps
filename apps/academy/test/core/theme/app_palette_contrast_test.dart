import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_palette.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// The bottom navigation's inactive labels used `textTertiary`, which against
/// the light theme's `backgroundSecondary` measures 2.6:1 — well under the
/// 4.5:1 WCAG AA floor for body text. In light mode the tab names were
/// effectively unreadable; in dark mode the same pair happened to pass, which
/// is why it survived review.
///
/// These pin the pairs the navigation actually uses, in both themes, so a
/// future palette edit cannot quietly drop one below AA again.
void main() {
  double relativeLuminance(Color color) {
    double channel(double value) => value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4) as double;
    return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
  }

  double contrastRatio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  const aaNormalText = 4.5;

  group('bottom navigation contrast', () {
    test('light: the inactive label clears AA against the bar', () {
      final AppColorTokens tokens = AppPalette.light;

      expect(contrastRatio(tokens.backgroundSecondary, tokens.textSecondary), greaterThanOrEqualTo(aaNormalText));
    });

    test('dark: the inactive label clears AA against the bar', () {
      final AppColorTokens tokens = AppPalette.dark;

      expect(contrastRatio(tokens.backgroundSecondary, tokens.textSecondary), greaterThanOrEqualTo(aaNormalText));
    });

    test('light: the selected label clears AA against the bar', () {
      final AppColorTokens tokens = AppPalette.light;

      expect(contrastRatio(tokens.backgroundSecondary, tokens.primary), greaterThanOrEqualTo(3.0));
    });

    // The tone this replaced, kept as the regression's own record: if a
    // future palette makes textTertiary AA-safe on the nav bar, this test is
    // the one to delete, deliberately.
    test('light: textTertiary is still the tone that would fail there', () {
      final AppColorTokens tokens = AppPalette.light;

      expect(contrastRatio(tokens.backgroundSecondary, tokens.textTertiary), lessThan(aaNormalText));
    });
  });
}
