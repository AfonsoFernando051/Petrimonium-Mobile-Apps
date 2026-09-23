import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/home/domain/entities/next_action.dart';
import 'package:petrimonium_academy/features/home/presentation/widgets/next_action_card.dart';

const _lesson = Lesson(
  id: 'lesson_1',
  moduleId: 'module_1',
  title: 'O que é Renda Fixa?',
  order: 1,
  xpReward: 25,
  steps: [ExplanationStep(title: 'Explain', body: 'Body')],
);

const _mission = MissionStatus(
  code: 'daily_complete_lesson',
  period: MissionPeriod.daily,
  periodKey: '2026-08-25',
  progress: 1,
  target: 2,
  xpReward: 15,
  completed: false,
);

void main() {
  setUp(() {
    Translator.currentLanguage = 'pt';
  });

  Widget buildTestableWidget({required NextAction action, VoidCallback? onStartLesson, VoidCallback? onOpenAcademy}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: NextActionCard(
          action: action,
          onStartLesson: onStartLesson ?? () {},
          onOpenAcademy: onOpenAcademy ?? () {},
        ),
      ),
    );
  }

  group('NextActionCard — ContinueLessonAction', () {
    const action = ContinueLessonAction(lesson: _lesson, moduleTitle: 'Fundamentos');

    testWidgets('renders the lesson title, XP reward and module title', (tester) async {
      await tester.pumpWidget(buildTestableWidget(action: action));

      expect(find.text('O que é Renda Fixa?'), findsOneWidget);
      expect(find.text('Fundamentos'), findsOneWidget);
      expect(find.text('+25 XP ao concluir'), findsOneWidget);
      expect(find.text('Continuar aula'), findsOneWidget);
      expect(find.text('CONTINUE APRENDENDO'), findsOneWidget);
    });

    testWidgets('omits the module title row when moduleTitle is null', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(action: const ContinueLessonAction(lesson: _lesson, moduleTitle: null)),
      );

      expect(find.text('O que é Renda Fixa?'), findsOneWidget);
      expect(find.text('Fundamentos'), findsNothing);
    });

    testWidgets('tapping the CTA invokes onStartLesson', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestableWidget(action: action, onStartLesson: () => tapped = true));

      await tester.tap(find.byType(GameButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('names where in the module the lesson sits, with duration, progress and goal', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          action: const ContinueLessonAction(
            lesson: _lesson,
            moduleTitle: 'Fundamentos',
            moduleLessonCount: 4,
            moduleCompletedCount: 1,
            lessonPosition: 2,
            estimatedMinutes: 8,
            goalLabel: 'Reserva de emergência',
          ),
        ),
      );

      expect(find.text('Aula 2 de 4 · ~8 min · +25 XP ao concluir'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Baseado no seu objetivo: Reserva de emergência'), findsOneWidget);
    });

    testWidgets('drops the parts that are not known instead of inventing them', (tester) async {
      await tester.pumpWidget(buildTestableWidget(action: action));

      expect(find.text('+25 XP ao concluir'), findsOneWidget);
      expect(find.textContaining('Aula '), findsNothing);
      expect(find.textContaining('min'), findsNothing);
      expect(find.textContaining('Baseado no seu objetivo'), findsNothing);
    });

    testWidgets('omits the duration when the lesson has no steps to estimate from', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          action: const ContinueLessonAction(
            lesson: _lesson,
            moduleTitle: 'Fundamentos',
            moduleLessonCount: 4,
            lessonPosition: 2,
            estimatedMinutes: 0,
          ),
        ),
      );

      expect(find.text('Aula 2 de 4 · +25 XP ao concluir'), findsOneWidget);
    });
  });

  group('NextActionCard — CompleteMissionAction', () {
    const action = CompleteMissionAction(_mission);

    testWidgets('renders the mission title and XP reward, not lesson content', (tester) async {
      await tester.pumpWidget(buildTestableWidget(action: action));

      expect(find.text('Aula do Dia'), findsOneWidget);
      expect(find.textContaining('+15 XP'), findsOneWidget);
      expect(find.text('Continuar Aprendendo'), findsOneWidget);
      expect(find.text('O que é Renda Fixa?'), findsNothing);
    });

    testWidgets('tapping the CTA invokes onStartLesson', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestableWidget(action: action, onStartLesson: () => tapped = true));

      await tester.tap(find.byType(GameButton));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('NextActionCard — AllLessonsCompleteAction', () {
    const action = AllLessonsCompleteAction();

    testWidgets('renders the completion message and explore CTA', (tester) async {
      await tester.pumpWidget(buildTestableWidget(action: action));

      expect(find.text('Você concluiu tudo por aqui!'), findsOneWidget);
      expect(
        find.text('Novos módulos chegam em breve. Explore a Academia para revisar o que já aprendeu.'),
        findsOneWidget,
      );
      expect(find.text('Ver Academia'), findsOneWidget);
    });

    testWidgets('tapping the explore CTA invokes onOpenAcademy', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTestableWidget(action: action, onOpenAcademy: () => tapped = true));

      await tester.tap(find.byType(GameButton));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
