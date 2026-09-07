import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/features/onboarding/data/repositories/wallet_market_preferences_repository.dart';
import 'package:petrimonium/features/onboarding/presentation/screens/quick_setup_screen.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    DI.walletMarketPreferencesRepository = WalletMarketPreferencesRepository();
  });

  Widget buildThemedTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: const QuickSetupScreen(),
    );
  }

  group('QuickSetupScreen', () {
    testWidgets('renders title, subtitle, field labels/values and footer note', (tester) async {
      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      expect(find.text('Antes de começar'), findsOneWidget);
      expect(find.text('Só o essencial — dá pra ajustar depois.'), findsOneWidget);
      expect(find.text('País / mercado'), findsOneWidget);
      expect(find.text('🇧🇷 Brasil · B3'), findsOneWidget);
      expect(find.text('Moeda-base'), findsOneWidget);
      expect(find.text('BRL — Real'), findsOneWidget);
      expect(
        find.text(
          'Você vai adicionar seus ativos manualmente no próximo passo — nada é importado automaticamente ainda.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('tapping the market field opens a sheet listing it, selectable', (tester) async {
      // GameButton's CTA pulse animation repeats forever (see
      // welcome_screen_test.dart's comment on the same constraint) — explicit
      // pumps only, never pumpAndSettle, for the whole test.
      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      await tester.tap(find.text('🇧🇷 Brasil · B3'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Sheet shows the option with a check mark, since it's already selected.
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('🇧🇷 Brasil · B3').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('🇧🇷 Brasil · B3'), findsOneWidget);
    });
  });
}
