import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium_wallet/core/di/dependency_injection.dart';
import 'package:petrimonium_wallet/core/theme/app_theme.dart';
import 'package:petrimonium_wallet/core/utils/translator.dart';
import 'package:petrimonium_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium_wallet/features/mentor/data/datasources/mentor_remote_datasource.dart';
import 'package:petrimonium_wallet/features/mentor/data/repositories/mentor_chat_repository.dart';
import 'package:petrimonium_wallet/features/mentor/domain/entities/chat_message.dart';
import 'package:petrimonium_wallet/features/mentor/presentation/screens/mentor_screen.dart';
import 'package:petrimonium_wallet/features/mentor/presentation/widgets/mentor_pet_stage.dart';
import 'package:petrimonium_wallet/features/mentor/presentation/widgets/mentor_speech_card.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_wallet/features/pet/domain/repositories/pet_repository.dart';

class MockMentorChatRepository extends Mock implements MentorChatRepository {}

class MockPetRepository extends Mock implements PetRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockMentorChatRepository mockMentorChatRepository;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    Translator.currentLanguage = 'pt';

    mockMentorChatRepository = MockMentorChatRepository();
    DI.mentorChatRepository = mockMentorChatRepository;
    when(() => mockMentorChatRepository.purgeLegacyLocalHistory()).thenAnswer((_) async {});
    when(
      () => mockMentorChatRepository.loadSuggestedPrompts(),
    ).thenAnswer((_) async => ['Como está minha carteira hoje?', 'O que é um ETF?']);

    final mockPetRepository = MockPetRepository();
    DI.petRepository = mockPetRepository;
    when(() => mockPetRepository.getMyPet()).thenAnswer((_) async => null);

    mockAuthRepository = MockAuthRepository();
    DI.authRepository = mockAuthRepository;
    when(() => mockAuthRepository.getSavedEmail()).thenAnswer((_) async => 'camila.souza@example.com');
  });

  void stubSend(Future<MentorChatResult> Function() answer) {
    when(
      () => mockMentorChatRepository.sendMessage(
        message: any(named: 'message'),
        conversationId: any(named: 'conversationId'),
        currentScreen: any(named: 'currentScreen'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<void> pumpScreen(WidgetTester tester, {int? initialConversationId}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: MentorScreen(initialConversationId: initialConversationId)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Lets the typewriter reveal finish without pumpAndSettle, which the pet's
  // endless motion would never let settle.
  Future<void> pumpReveal(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('MentorScreen', () {
    testWidgets('welcomes by name with the pet and the suggested prompts as starters', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('Seu companheiro financeiro'), findsOneWidget);
      expect(find.text('Oi, Camila 👋'), findsOneWidget);
      expect(find.text('O que vamos descobrir hoje?'), findsOneWidget);
      expect(find.byType(MentorPetStage), findsOneWidget);
      expect(find.widgetWithText(SuggestedPromptChip, 'Como está minha carteira hoje?'), findsOneWidget);
      expect(find.byType(MentorInputBar), findsOneWidget);
    });

    testWidgets('greets without a name when none is known', (tester) async {
      when(() => mockAuthRepository.getSavedEmail()).thenAnswer((_) async => null);

      await pumpScreen(tester);

      expect(find.text('Oi 👋'), findsOneWidget);
    });

    testWidgets('the info button toggles the regulatory disclaimer', (tester) async {
      await pumpScreen(tester);
      const disclaimer =
          'Não executa transações. Não substitui consultoria financeira regulada — apenas ajuda a interpretar seus dados.';
      expect(find.text(disclaimer), findsNothing);

      await tester.tap(find.byTooltip('Sobre o Mentor'));
      await tester.pump();
      expect(find.text(disclaimer), findsOneWidget);

      await tester.tap(find.byTooltip('Sobre o Mentor'));
      await tester.pump();
      expect(find.text(disclaimer), findsNothing);
    });

    testWidgets('a starter shows the thinking stage, then the reply in the speech card', (tester) async {
      final gate = Completer<MentorChatResult>();
      stubSend(() => gate.future);

      await pumpScreen(tester);
      await tester.tap(find.text('Como está minha carteira hoje?'));
      await tester.pump();

      verify(
        () => mockMentorChatRepository.sendMessage(
          message: 'Como está minha carteira hoje?',
          conversationId: any(named: 'conversationId'),
          currentScreen: 'mentor',
        ),
      ).called(1);
      expect(find.text('Deixa eu ver isso pra você...'), findsOneWidget);
      expect(find.byType(MentorSpeechCard), findsNothing);

      gate.complete(const MentorChatResult(reply: 'Está estável.', conversationId: 1, title: 'Sua carteira hoje'));
      await tester.pump();
      await pumpReveal(tester);

      expect(find.text('Deixa eu ver isso pra você...'), findsNothing);
      expect(find.byType(MentorSpeechCard), findsOneWidget);
      expect(find.text('SUA CARTEIRA HOJE'), findsOneWidget);
      expect(find.text('Está estável.'), findsOneWidget);
    });

    testWidgets('"Perguntar outra coisa" goes back to the welcome stage', (tester) async {
      stubSend(() async => const MentorChatResult(reply: 'Está estável.', conversationId: 1));

      await pumpScreen(tester);
      await tester.tap(find.text('Como está minha carteira hoje?'));
      await tester.pump();
      await pumpReveal(tester);

      await tester.tap(find.text('Perguntar outra coisa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MentorSpeechCard), findsNothing);
      expect(find.text('O que vamos descobrir hoje?'), findsOneWidget);
    });

    testWidgets('typing a message and tapping send clears the input field', (tester) async {
      stubSend(() async => const MentorChatResult(reply: 'Olá!', conversationId: 2));

      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'Oi mentor');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      await pumpReveal(tester);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
      verify(
        () => mockMentorChatRepository.sendMessage(
          message: 'Oi mentor',
          conversationId: any(named: 'conversationId'),
          currentScreen: 'mentor',
        ),
      ).called(1);
    });

    testWidgets('opening a past conversation puts its last reply on stage', (tester) async {
      when(() => mockMentorChatRepository.loadConversation(4)).thenAnswer(
        (_) async => [
          ChatMessage(id: '1', role: ChatRole.user, text: 'Recebi proventos?', timestamp: DateTime(2024, 1, 1)),
          ChatMessage(id: '2', role: ChatRole.mentor, text: 'Recebeu sim.', timestamp: DateTime(2024, 1, 1)),
        ],
      );

      await pumpScreen(tester, initialConversationId: 4);

      expect(find.byType(MentorSpeechCard), findsOneWidget);
      expect(find.text('Recebeu sim.'), findsOneWidget);
    });
  });
}
