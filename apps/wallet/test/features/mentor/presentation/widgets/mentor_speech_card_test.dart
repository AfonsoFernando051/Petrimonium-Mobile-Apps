import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/mentor/domain/entities/chat_message.dart';
import 'package:petrimonium_wallet/features/mentor/presentation/widgets/mentor_speech_card.dart';

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

  ChatMessage reply(String text, {bool isError = false, List<String> sources = const [], DateTime? timestamp}) {
    return ChatMessage(
      id: 'r',
      role: ChatRole.mentor,
      text: text,
      timestamp: timestamp ?? DateTime(2024, 1, 1),
      isError: isError,
      sources: sources,
    );
  }

  group('MentorSpeechCard', () {
    testWidgets('shows the topic uppercased as a pill when there is one', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('Tudo certo.'), topic: 'Queda da carteira'));

      expect(find.text('QUEDA DA CARTEIRA'), findsOneWidget);
    });

    testWidgets('shows no pill when the conversation has no topic', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('Tudo certo.')));

      expect(find.text('Tudo certo.'), findsOneWidget);
      expect(find.text('TUDO CERTO.'), findsNothing);
    });

    testWidgets('renders a plain reply as a single markdown block, not layered chips', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('Oi! Como posso ajudar hoje?')));

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('DADO'), findsNothing);
      expect(find.text('CÁLCULO DETERMINÍSTICO'), findsNothing);
      expect(find.text('MENTOR · INTERPRETAÇÃO'), findsNothing);
    });

    testWidgets('renders a structured reply with each real layer under its own chip', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          reply(
            '[[DATA]]\nSuas ações e FIIs desvalorizaram no período.\n'
            r'[[CALCULATION]]'
            '\n- R\$ 812,40 (-1,7%) no mês\n'
            '[[INTERPRETATION]]\nIsso acompanhou o mercado.',
            timestamp: DateTime(2024, 3, 15, 9, 41),
          ),
        ),
      );

      expect(find.textContaining('DADO · brapi.dev, 15/03 09:41'), findsOneWidget);
      expect(find.text('Suas ações e FIIs desvalorizaram no período.'), findsOneWidget);
      expect(find.text('CÁLCULO DETERMINÍSTICO'), findsOneWidget);
      expect(find.textContaining('812,40'), findsOneWidget);
      expect(find.text('MENTOR · INTERPRETAÇÃO'), findsOneWidget);
      expect(find.text('Isso acompanhou o mercado.'), findsOneWidget);
    });

    testWidgets('an error reply never parses as layers even if it contains marker-like text', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('[[DATA]]\nAlgo deu errado.', isError: true)));

      expect(find.textContaining('DADO'), findsNothing);
      expect(find.textContaining('[[DATA]]'), findsOneWidget);
    });

    testWidgets('a reply with no sources has no "why am I seeing this" link', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('Sem fontes reais.')));

      expect(find.text('Por que estou vendo isto?'), findsNothing);
    });

    testWidgets('a reply with real sources reveals them on tap', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(reply('Baseado na sua carteira.', sources: const ['portfolio_summary', 'client_goal'])),
      );

      expect(find.text('Sua carteira'), findsNothing);

      await tester.tap(find.text('Por que estou vendo isto?'));
      await tester.pump();

      expect(find.text('Sua carteira'), findsOneWidget);
      expect(find.text('Seu objetivo'), findsOneWidget);
    });

    testWidgets('an unknown source key falls back to the raw key rather than hiding it', (tester) async {
      await tester.pumpWidget(buildTestableWidget(reply('Fonte nova.', sources: const ['some_future_source'])));

      await tester.tap(find.text('Por que estou vendo isto?'));
      await tester.pump();

      expect(find.text('some_future_source'), findsOneWidget);
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
