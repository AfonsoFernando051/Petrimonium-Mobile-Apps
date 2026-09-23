import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/simulated_wallet/presentation/widgets/simulation_disclaimer_banner.dart';

/// This banner carries the only regulatory copy in the product ("no real
/// order is executed", "not financial advice"), so it is the one string that
/// must never be caught speaking the wrong language.
///
/// Both call sites instantiate it as `const`. A const widget is canonicalised,
/// so when the language changes Flutter sees an identical widget instance and
/// skips the rebuild — which is exactly how a user who switched to English
/// kept reading the Portuguese disclaimer on the wallet screen while the
/// freshly pushed order form showed the English one.
void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  tearDown(() {
    Translator.currentLanguage = 'pt';
  });

  // Deliberately const, and deliberately reused: this is what the screens do.
  final banner = MaterialApp(
    theme: AppTheme.dark,
    home: const Scaffold(body: SimulationDisclaimerBanner()),
  );

  Finder disclaimerStartingWith(String prefix) =>
      find.byWidgetPredicate((widget) => widget is Text && (widget.data ?? '').startsWith(prefix));

  testWidgets('speaks the language chosen at build time', (tester) async {
    await tester.pumpWidget(banner);

    expect(disclaimerStartingWith('Carteira de simulação'), findsOneWidget);
  });

  testWidgets('follows a language switch even though the caller cannot rebuild it', (tester) async {
    await tester.pumpWidget(banner);
    expect(disclaimerStartingWith('Carteira de simulação'), findsOneWidget);

    Translator.currentLanguage = 'en';
    await tester.pump();

    expect(disclaimerStartingWith('Simulation wallet'), findsOneWidget);
    expect(disclaimerStartingWith('Carteira de simulação'), findsNothing);
  });

  testWidgets('follows a switch to Spanish too', (tester) async {
    await tester.pumpWidget(banner);

    Translator.currentLanguage = 'es';
    await tester.pump();

    expect(disclaimerStartingWith('Carteira de simulação'), findsNothing);
    expect(disclaimerStartingWith('Simulation wallet'), findsNothing);
  });

  testWidgets('keeps the warning chrome around the copy', (tester) async {
    await tester.pumpWidget(banner);

    expect(find.byIcon(Icons.science_outlined), findsOneWidget);
  });

  testWidgets('switching back restores the original copy', (tester) async {
    await tester.pumpWidget(banner);

    Translator.currentLanguage = 'en';
    await tester.pump();
    Translator.currentLanguage = 'pt';
    await tester.pump();

    expect(disclaimerStartingWith('Carteira de simulação'), findsOneWidget);
  });
}
