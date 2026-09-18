import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/mentor/domain/entities/chat_message.dart';
import 'package:petrimonium_academy/features/mentor/presentation/widgets/mentor_speech_card.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget(ChatMessage reply, {String? topic, ValueListenable<String>? revealingText}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MentorSpeechCard(reply: reply, topic: topic, revealingText: revealingText),
        ),
      ),
    );
  }

  ChatMessage reply(String text, {bool isError = false, DateTime? timestamp}) {
    return ChatMessage(
      id: 'r',
      role: ChatRole.mentor,
      text: text,
      timestamp: timestamp ?? DateTime(2024, 1, 1),
      isError: isError,
    );
  }

  group('MentorSpeechCard', () {
    testWidgets('shows the topic uppercased as a pill when there is one', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('Tudo certo.'), topic: 'O que é diversificação'));

      expect(find.text('O QUE É DIVERSIFICAÇÃO'), findsOneWidget);
    });

    testWidgets('shows no pill when the conversation has no topic', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('Tudo certo.')));

      expect(find.text('Tudo certo.'), findsOneWidget);
      expect(find.text('TUDO CERTO.'), findsNothing);
    });

    testWidgets('renders a plain reply as a single markdown block, not layered chips', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('Oi! Posso te ajudar com o que quiser.')));

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.text('CONTEÚDO EDUCATIVO'), findsNothing);
      expect(find.text('MENTOR · INTERPRETAÇÃO DE IA'), findsNothing);
    });

    testWidgets('renders a structured reply with content and interpretation under their own chips', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          reply(
            '[[CONTENT]]\nDiversificação é distribuir seu dinheiro entre ativos diferentes.\n'
            '[[INTERPRETATION]]\nAssim, se um ativo cair, os outros amortecem o impacto.',
          ),
        ),
      );

      expect(find.text('CONTEÚDO EDUCATIVO'), findsOneWidget);
      expect(find.text('Diversificação é distribuir seu dinheiro entre ativos diferentes.'), findsOneWidget);
      expect(find.text('MENTOR · INTERPRETAÇÃO DE IA'), findsOneWidget);
      expect(find.text('Assim, se um ativo cair, os outros amortecem o impacto.'), findsOneWidget);
    });

    testWidgets('an error reply never parses as layers even if it contains marker-like text', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('[[CONTENT]]\nAlgo deu errado.', isError: true)));

      expect(find.text('CONTEÚDO EDUCATIVO'), findsNothing);
      expect(find.textContaining('[[CONTENT]]'), findsOneWidget);
    });

    group('revealingText (typewriter reveal)', () {
      testWidgets('renders the notifier value instead of the (still empty) stored reply text', (tester) async {
        await tester.pumpWidget(buildTestableWidget(reply(''), revealingText: ValueNotifier<String>('Olá')));

        expect(find.text('Olá'), findsOneWidget);
      });

      testWidgets('updates when the notifier changes, without needing a new widget instance', (tester) async {
        final revealingText = ValueNotifier<String>('Ol');
        await tester.pumpWidget(buildTestableWidget(reply(''), revealingText: revealingText));

        revealingText.value = 'Olá!';
        await tester.pump();

        expect(find.text('Olá!'), findsOneWidget);
        expect(find.text('Ol'), findsNothing);
      });

      testWidgets('an empty reveal renders no markdown yet', (tester) async {
        await tester.pumpWidget(buildTestableWidget(reply(''), revealingText: ValueNotifier<String>('')));

        expect(find.byType(MarkdownBody), findsNothing);
      });
    });
  });
}
