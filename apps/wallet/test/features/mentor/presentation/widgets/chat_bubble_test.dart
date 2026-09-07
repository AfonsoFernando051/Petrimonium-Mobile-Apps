import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/features/mentor/domain/entities/chat_message.dart';
import 'package:petrimonium/features/mentor/presentation/widgets/chat_bubble.dart';

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget(ChatMessage message) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: ChatBubble(message: message)),
    );
  }

  group('ChatBubble', () {
    testWidgets('renders a user message as plain right-aligned text', (tester) async {
      final message = ChatMessage(
        id: '1',
        role: ChatRole.user,
        text: 'O que são dividendos?',
        timestamp: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(buildTestableWidget(message));

      expect(find.text('O que são dividendos?'), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('renders a mentor message left-aligned with markdown', (tester) async {
      final message = ChatMessage(
        id: '2',
        role: ChatRole.mentor,
        text: '**Claro!** Posso ajudar.',
        timestamp: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(buildTestableWidget(message));

      expect(find.byType(MarkdownBody), findsOneWidget);
      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('renders an empty mentor message without a MarkdownBody (typewriter reveal in progress)', (tester) async {
      final message = ChatMessage(
        id: '3',
        role: ChatRole.mentor,
        text: '',
        timestamp: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(buildTestableWidget(message));

      expect(find.byType(MarkdownBody), findsNothing);
    });

    testWidgets('an error mentor message still renders through the mentor (markdown) path', (tester) async {
      final message = ChatMessage(
        id: '4',
        role: ChatRole.mentor,
        text: 'Algo deu errado.',
        timestamp: DateTime(2024, 1, 1),
        isError: true,
      );

      await tester.pumpWidget(buildTestableWidget(message));

      expect(find.byType(MarkdownBody), findsOneWidget);
      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('a mentor message with no sources has no "why am I seeing this" link', (tester) async {
      final message = ChatMessage(
        id: '5',
        role: ChatRole.mentor,
        text: 'Sem fontes reais para essa resposta.',
        timestamp: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(buildTestableWidget(message));

      expect(find.text('Por que estou vendo isto?'), findsNothing);
    });

    testWidgets('a mentor message with real sources reveals them on tap', (tester) async {
      final message = ChatMessage(
        id: '6',
        role: ChatRole.mentor,
        text: 'Baseado na sua carteira atual.',
        timestamp: DateTime(2024, 1, 1),
        sources: const ['portfolio_summary', 'client_goal'],
      );

      await tester.pumpWidget(buildTestableWidget(message));

      expect(find.text('Por que estou vendo isto?'), findsOneWidget);
      expect(find.text('Sua carteira'), findsNothing);

      await tester.tap(find.text('Por que estou vendo isto?'));
      await tester.pump();

      expect(find.text('Sua carteira'), findsOneWidget);
      expect(find.text('Seu objetivo'), findsOneWidget);
    });

    testWidgets('an unknown source key falls back to the raw key rather than hiding it', (tester) async {
      final message = ChatMessage(
        id: '7',
        role: ChatRole.mentor,
        text: 'Resposta com fonte nova.',
        timestamp: DateTime(2024, 1, 1),
        sources: const ['some_future_source'],
      );

      await tester.pumpWidget(buildTestableWidget(message));
      await tester.tap(find.text('Por que estou vendo isto?'));
      await tester.pump();

      expect(find.text('some_future_source'), findsOneWidget);
    });

    testWidgets('a structured reply renders each real layer under its own chip', (tester) async {
      final message = ChatMessage(
        id: '8',
        role: ChatRole.mentor,
        text: '[[DATA]]\nSuas ações e FIIs desvalorizaram no período.\n'
            r'[[CALCULATION]]' '\n- R\$ 812,40 (-1,7%) no mês\n'
            '[[INTERPRETATION]]\nIsso é normal em mercados voláteis.',
        timestamp: DateTime(2024, 3, 15, 9, 41),
      );

      await tester.pumpWidget(buildTestableWidget(message));

      expect(find.textContaining('DADO · brapi.dev, 15/03 09:41'), findsOneWidget);
      expect(find.text('Suas ações e FIIs desvalorizaram no período.'), findsOneWidget);
      expect(find.text('CÁLCULO DETERMINÍSTICO'), findsOneWidget);
      expect(find.textContaining('812,40'), findsOneWidget);
      expect(find.text('MENTOR · INTERPRETAÇÃO'), findsOneWidget);
      expect(find.text('Isso é normal em mercados voláteis.'), findsOneWidget);
    });

    testWidgets('a plain reply with no markers renders as a single block, not layered chips', (tester) async {
      final message = ChatMessage(
        id: '9',
        role: ChatRole.mentor,
        text: 'Oi! Como posso ajudar hoje?',
        timestamp: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(buildTestableWidget(message));

      expect(find.text('Oi! Como posso ajudar hoje?'), findsOneWidget);
      expect(find.textContaining('DADO'), findsNothing);
      expect(find.text('CÁLCULO DETERMINÍSTICO'), findsNothing);
      expect(find.text('MENTOR · INTERPRETAÇÃO'), findsNothing);
    });

    testWidgets('an error message never parses as layers even if it contains marker-like text', (tester) async {
      final message = ChatMessage(
        id: '10',
        role: ChatRole.mentor,
        text: '[[DATA]]\nAlgo deu errado.',
        timestamp: DateTime(2024, 1, 1),
        isError: true,
      );

      await tester.pumpWidget(buildTestableWidget(message));

      expect(find.textContaining('DADO'), findsNothing);
      expect(find.textContaining('[[DATA]]'), findsOneWidget);
    });
  });
}
