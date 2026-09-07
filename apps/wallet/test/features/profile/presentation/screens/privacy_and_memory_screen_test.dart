import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/game_button.dart';
import 'package:petrimonium/features/mentor/presentation/screens/conversation_list_screen.dart';
import 'package:petrimonium/features/profile/presentation/screens/privacy_and_memory_screen.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestable() {
    return MaterialApp(theme: AppTheme.dark, home: const PrivacyAndMemoryScreen());
  }

  group('PrivacyAndMemoryScreen', () {
    testWidgets('renders the explanation and the saved-conversations CTA', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pump();

      expect(find.textContaining('O Mentor usa seu objetivo'), findsOneWidget);
      expect(find.text('Ver conversas salvas'), findsOneWidget);
    });

    testWidgets('tapping the CTA navigates to ConversationListScreen', (tester) async {
      await tester.pumpWidget(buildTestable());
      await tester.pump();

      await tester.tap(find.byType(GameButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ConversationListScreen), findsOneWidget);
    });
  });
}
