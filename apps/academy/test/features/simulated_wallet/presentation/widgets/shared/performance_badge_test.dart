import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/shared/performance_badge.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

void main() {
  for (final percent in [-0.00001, -0.0, 0.0, 0.00001, -1.0, 1.0]) {
    testWidgets('performance $percent uses the rounded value for its sign and color', (tester) async {
      Translator.currentLanguage = 'pt';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: PerformanceBadge(percent: percent)),
        ),
      );
      final context = tester.element(find.byType(PerformanceBadge));
      final neutral = percent.abs() < 0.005;
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(
        icon.icon,
        neutral
            ? Icons.remove
            : percent > 0
            ? Icons.arrow_drop_up
            : Icons.arrow_drop_down,
      );
      expect(
        icon.color,
        neutral
            ? context.colors.textSecondary
            : percent > 0
            ? context.colors.success
            : context.colors.error,
      );
      if (neutral) expect(find.text('0,00%'), findsOneWidget);
    });
  }
}
