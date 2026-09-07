import 'package:flutter/material.dart';
import 'package:petrimonium/core/theme/app_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

void main() {
  group('AppColorTokens', () {
    test('dark and light presets are distinct', () {
      expect(AppPalette.dark.backgroundPrimary, isNot(AppPalette.light.backgroundPrimary));
      expect(AppPalette.dark.textPrimary, isNot(AppPalette.light.textPrimary));
    });

    test('copyWith overrides only the given fields', () {
      final copy = AppPalette.dark.copyWith(primary: Colors.red);

      expect(copy.primary, Colors.red);
      expect(copy.backgroundPrimary, AppPalette.dark.backgroundPrimary);
      expect(copy.textPrimary, AppPalette.dark.textPrimary);
    });

    test('copyWith with no arguments returns an equivalent instance', () {
      final copy = AppPalette.dark.copyWith();

      expect(copy.primary, AppPalette.dark.primary);
      expect(copy.surface, AppPalette.dark.surface);
    });

    test('lerp at t=0 returns the starting instance colors', () {
      final result = AppPalette.dark.lerp(AppPalette.light, 0);

      expect(result.backgroundPrimary, AppPalette.dark.backgroundPrimary);
    });

    test('lerp at t=1 returns the other instance colors', () {
      final result = AppPalette.dark.lerp(AppPalette.light, 1);

      expect(result.backgroundPrimary, AppPalette.light.backgroundPrimary);
    });

    test('lerp with a non-AppColorTokens other returns this unchanged', () {
      final result = AppPalette.dark.lerp(null, 0.5);

      expect(result, AppPalette.dark);
    });
  });

  group('AppThemeContextX', () {
    testWidgets('context.colors resolves the registered AppColorTokens extension', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: [AppPalette.dark]),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedContext.colors, AppPalette.dark);
    });

    testWidgets('context.isDarkMode reflects the theme brightness', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedContext.isDarkMode, isTrue);
    });
  });
}
