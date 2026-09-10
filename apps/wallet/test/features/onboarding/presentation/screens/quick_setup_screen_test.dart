import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/onboarding/data/repositories/wallet_market_preferences_repository.dart';
import 'package:petrimonium_wallet/features/onboarding/presentation/screens/quick_setup_screen.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    DI.walletMarketPreferencesRepository = WalletMarketPreferencesRepository();
  });

  Widget buildThemedTestableWidget() {
    return MaterialApp(theme: AppTheme.dark, home: const QuickSetupScreen());
  }

  group('QuickSetupScreen', () {
    testWidgets('renders title, subtitle, field labels/values and footer note', (tester) async {
      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      expect(find.text('Antes de começar'), findsOneWidget);
      expect(find.text('Só o essencial — dá pra ajustar depois.'), findsOneWidget);
      expect(find.text('País / mercado'), findsOneWidget);
      // As opções ficam à vista em pastilhas, com a bandeira à parte do
      // rótulo — o artboard `PrefsWallet` não usa campo que abre folha.
      expect(find.text('Brasil · B3'), findsOneWidget);
      expect(find.text('🇧🇷'), findsOneWidget);
      expect(find.text('Moeda-base'), findsOneWidget);
      expect(find.text('BRL — Real'), findsOneWidget);
      expect(find.byType(OptionPill), findsNWidgets(2));
      expect(
        find.text(
          'Você vai adicionar seus ativos manualmente no próximo passo — nada é importado automaticamente ainda.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('shows the choices inline and marks the current one, with no modal', (tester) async {
      // GameButton's CTA pulse animation repeats forever (see
      // welcome_screen_test.dart's comment on the same constraint) — explicit
      // pumps only, never pumpAndSettle, for the whole test.
      await tester.pumpWidget(buildThemedTestableWidget());
      await tester.pump();

      final marketPill = find.ancestor(of: find.text('Brasil · B3'), matching: find.byType(OptionPill));
      expect(tester.widget<OptionPill>(marketPill).selected, isTrue);

      await tester.tap(find.text('Brasil · B3'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Nada de folha modal: a escolha resolve-se no próprio ecrã.
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.widget<OptionPill>(marketPill).selected, isTrue);
    });
  });
}
