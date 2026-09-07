import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/features/home/presentation/widgets/mentor_insight_card.dart';
import 'package:petrimonium/features/mentor/data/datasources/mentor_remote_datasource.dart';
import 'package:petrimonium/features/mentor/data/repositories/mentor_chat_repository.dart';

class MockMentorChatRepository extends Mock implements MentorChatRepository {}

void main() {
  late MockMentorChatRepository mockRepository;

  setUp(() {
    mockRepository = MockMentorChatRepository();
    DI.mentorChatRepository = mockRepository;
  });

  Widget buildTestableWidget({int? Function()? onOpenMentorCapture}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: MentorInsightCard(onOpenMentor: (id) => onOpenMentorCapture?.call()),
      ),
    );
  }

  group('MentorInsightCard', () {
    testWidgets('fetches a real reply and shows it, dismissible', (tester) async {
      when(
        () => mockRepository.sendMessage(
          message: any(named: 'message'),
          conversationId: any(named: 'conversationId'),
          currentScreen: any(named: 'currentScreen'),
        ),
      ).thenAnswer(
        (_) async => const MentorChatResult(
          reply: 'Seus aportes cobriram a queda de mercado no período.',
          conversationId: 42,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('Seus aportes cobriram a queda de mercado no período.'), findsOneWidget);
      expect(find.text('Por que estou vendo isto?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.text('Mentor'), findsNothing);
    });

    testWidgets('renders nothing when the backend call fails', (tester) async {
      when(
        () => mockRepository.sendMessage(
          message: any(named: 'message'),
          conversationId: any(named: 'conversationId'),
          currentScreen: any(named: 'currentScreen'),
        ),
      ).thenThrow(Exception('network down'));

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Mentor'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping "Por que estou vendo isto?" opens the Mentor tab with the real conversation id', (tester) async {
      when(
        () => mockRepository.sendMessage(
          message: any(named: 'message'),
          conversationId: any(named: 'conversationId'),
          currentScreen: any(named: 'currentScreen'),
        ),
      ).thenAnswer(
        (_) async => const MentorChatResult(reply: 'Interpretação.', conversationId: 42),
      );

      int? capturedId;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: MentorInsightCard(onOpenMentor: (id) => capturedId = id),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Por que estou vendo isto?'));
      await tester.pump();

      expect(capturedId, 42);
    });
  });
}
