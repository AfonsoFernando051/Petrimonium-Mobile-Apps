import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/widgets/cosmic_background.dart';

void main() {
  group('CosmicBackground', () {
    testWidgets('renders its child on a flat petrol-green gradient (dark theme)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: CosmicBackground(child: Text('content')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('content'), findsOneWidget);
      final decoration = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, [AppTheme.dark.extension<AppColorTokens>()!.backgroundPrimary, AppTheme.dark.extension<AppColorTokens>()!.backgroundSecondary]);
    });

    testWidgets('renders its child on the light theme equivalent gradient', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CosmicBackground(child: Text('content')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('content'), findsOneWidget);
      final decoration = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, [AppTheme.light.extension<AppColorTokens>()!.backgroundPrimary, AppTheme.light.extension<AppColorTokens>()!.backgroundSecondary]);
    });
  });
}
