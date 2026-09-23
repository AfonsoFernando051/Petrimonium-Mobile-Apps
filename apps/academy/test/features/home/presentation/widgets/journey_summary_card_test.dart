import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/academy/domain/entities/journey_stage.dart';
import 'package:petrimonium_academy/features/academy/domain/services/academy_progress_calculator.dart';
import 'package:petrimonium_academy/features/home/domain/services/journey_summary_resolver.dart';
import 'package:petrimonium_academy/features/home/presentation/widgets/journey_summary_card.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

import '../../../academy/academy_test_fixtures.dart';

JourneyModuleEntry moduleWith({required int lessons, required int completed}) {
  return JourneyModuleEntry(
    module: testModule,
    status: ModuleStatus.inProgress,
    completedLessons: completed,
    isCurrent: true,
    lessons: [
      for (var i = 0; i < lessons; i++)
        JourneyLessonEntry(
          lesson: testLesson1,
          status: i < completed ? LessonStatus.completed : LessonStatus.available,
          isNext: i == completed,
          estimatedMinutes: 3,
        ),
    ],
  );
}

JourneyStage stage(int position, JourneyStageState state, {List<JourneyModuleEntry> modules = const []}) {
  return JourneyStage(
    school: School(
      id: 'school_$position',
      title: 'Escola $position',
      description: 'desc',
      iconKey: 'savings_outlined',
      order: position,
      contentAvailable: true,
    ),
    domain: null,
    position: position,
    state: state,
    completedLessons: state == JourneyStageState.completed ? 10 : 6,
    modules: modules,
  );
}

void main() {
  setUp(() => Translator.currentLanguage = 'pt');

  /// Twelve stages, the learner on the third — the shape that used to make
  /// Home a catalog of every school.
  List<JourneyStage> longJourney() => [
    stage(1, JourneyStageState.completed),
    stage(2, JourneyStageState.completed),
    stage(3, JourneyStageState.current, modules: [moduleWith(lessons: 10, completed: 6)]),
    stage(4, JourneyStageState.upNext),
    for (var i = 5; i <= 12; i++) stage(i, JourneyStageState.upcoming),
  ];

  Widget buildTestable(List<JourneyStage> journey, {VoidCallback? onOpenJourney}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: JourneySummaryCard(
          summary: JourneySummaryResolver.resolve(journey)!,
          onOpenJourney: onOpenJourney ?? () {},
        ),
      ),
    );
  }

  group('JourneySummaryCard', () {
    testWidgets('names where the learner stands, with real stage and lesson progress', (tester) async {
      await tester.pumpWidget(buildTestable(longJourney()));

      expect(find.text('SUA JORNADA'), findsOneWidget);
      expect(find.text('Escola 3'), findsOneWidget);
      expect(find.text('Etapa 3 de 12 · 6 de 10 aulas'), findsOneWidget);
      expect(find.text('A seguir: Escola 4'), findsOneWidget);
      expect(find.text('Ver jornada completa'), findsOneWidget);
    });

    testWidgets('never lists the whole curriculum', (tester) async {
      await tester.pumpWidget(buildTestable(longJourney()));

      // Only the stage the learner is on and the one right after it are
      // ever named — the rest of the journey belongs to the Academia tab.
      for (final position in [1, 2, 5, 6, 7, 8, 9, 10, 11, 12]) {
        expect(find.text('Escola $position'), findsNothing);
      }
    });

    testWidgets('opens the journey when tapped', (tester) async {
      var opened = 0;
      await tester.pumpWidget(buildTestable(longJourney(), onOpenJourney: () => opened++));

      await tester.tap(find.text('Ver jornada completa'));
      await tester.pump();

      expect(opened, 1);
    });

    testWidgets('celebrates a finished journey instead of showing a stage in progress', (tester) async {
      await tester.pumpWidget(
        buildTestable([
          stage(1, JourneyStageState.completed),
          stage(2, JourneyStageState.completed),
          stage(3, JourneyStageState.comingSoon),
        ]),
      );

      expect(find.text('Você percorreu toda a jornada disponível'), findsOneWidget);
      expect(find.text('2 de 3 etapas concluídas'), findsOneWidget);
      expect(find.textContaining('A seguir'), findsNothing);
    });
  });
}
