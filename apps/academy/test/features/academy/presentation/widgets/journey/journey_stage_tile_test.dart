import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/features/academy/domain/entities/journey_stage.dart';
import 'package:petrimonium_academy/features/academy/domain/services/academy_progress_calculator.dart';
import 'package:petrimonium_academy/features/academy/presentation/widgets/journey/journey_stage_tile.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/rive/pet_rive_companion.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// Minimal in-memory MascotRepository double, mirrors
/// `lesson_complete_card_test.dart` — CAT rather than the default species,
/// since DOG's real `dog.riv` crashes `flutter_tester` on this toolchain.
class FakeMascotRepository implements MascotRepository {
  @override
  Future<PetProfile> loadProfile() async => PetProfile(specie: PetSpecieEnum.CAT);
  @override
  Future<void> saveName(String name) async {}
  @override
  Future<void> saveStage(PetEvolutionStage stage) async {}
  @override
  Future<void> saveXp(int xp) async {}
  @override
  Future<void> saveSpecie(PetSpecieEnum specie) async {}
  @override
  Future<void> saveNetWorth(double netWorth) async {}
  @override
  Future<void> saveEquippedAccessories(Map<AccessoryType, PetAccessoryId> equipped) async {}
  @override
  Future<void> saveUnlockedAccessories(Set<PetAccessoryId> unlocked) async {}
  @override
  Future<void> saveLastActiveAt(DateTime lastActiveAt) async {}
}

const _school = School(
  id: 's1',
  title: 'Vida Financeira',
  description: 'Dinheiro, metas e organização.',
  iconKey: 'savings_outlined',
  order: 1,
  contentAvailable: true,
);

const _lessonA = Lesson(
  id: 'l1',
  moduleId: 'm1',
  title: 'Por onde começar',
  order: 1,
  xpReward: 10,
  steps: [ExplanationStep(title: 'a', body: 'b')],
);
const _lessonB = Lesson(
  id: 'l2',
  moduleId: 'm1',
  title: 'Metas e prioridades',
  order: 2,
  xpReward: 10,
  steps: [ExplanationStep(title: 'a', body: 'b')],
);

const _module = AcademyModule(
  id: 'm1',
  schoolId: 's1',
  title: 'Fundamentos do Dinheiro',
  description: '',
  iconKey: 'savings_outlined',
  order: 1,
  lessonIds: ['l1', 'l2'],
  contentAvailable: true,
);

JourneyStage _stage({
  required JourneyStageState state,
  int completedLessons = 0,
  List<String> missingPrerequisites = const [],
  bool withModule = true,
}) {
  final isCurrent = state == JourneyStageState.current;
  return JourneyStage(
    school: _school,
    domain: null,
    position: 2,
    state: state,
    completedLessons: completedLessons,
    missingPrerequisites: missingPrerequisites,
    modules: withModule
        ? [
            JourneyModuleEntry(
              module: _module,
              status: isCurrent ? ModuleStatus.inProgress : ModuleStatus.available,
              completedLessons: completedLessons,
              isCurrent: isCurrent,
              lessons: [
                JourneyLessonEntry(
                  lesson: _lessonA,
                  status: completedLessons > 0 ? LessonStatus.completed : LessonStatus.available,
                  isNext: isCurrent && completedLessons > 0,
                  estimatedMinutes: 1,
                ),
                JourneyLessonEntry(
                  lesson: _lessonB,
                  status: LessonStatus.available,
                  isNext: isCurrent && completedLessons == 0,
                  estimatedMinutes: 2,
                ),
              ],
            ),
          ]
        : const [],
  );
}

void main() {
  late MascotController mascotController;

  setUp(() async {
    Translator.currentLanguage = 'pt';
    mascotController = MascotController(repository: FakeMascotRepository());
    await mascotController.loadProfile();
  });

  tearDown(() => mascotController.dispose());

  Widget buildTestable(
    JourneyStage stage, {
    bool isExpanded = true,
    String? masteryLabel,
    VoidCallback? onContinue,
    void Function(AcademyModule)? onOpenModule,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: JourneyStageTile(
            stage: stage,
            isExpanded: isExpanded,
            isLast: false,
            masteryLabel: masteryLabel,
            mascotController: mascotController,
            onToggle: () {},
            onOpenModule: onOpenModule ?? (_) {},
            onContinue: onContinue ?? () {},
          ),
        ),
      ),
    );
  }

  group('JourneyStageTile', () {
    testWidgets('the current stage says where the learner is, how far along, and what to do next', (tester) async {
      await tester.pumpWidget(buildTestable(_stage(state: JourneyStageState.current)));
      await tester.pump();

      expect(find.text(Translator.translate(AppStrings.academyJourneyYouAreHere).toUpperCase()), findsOneWidget);
      expect(
        find.text(
          Translator.translate(AppStrings.academyJourneyStageProgress, params: {'completed': '0', 'total': '2'}),
        ),
        findsOneWidget,
      );
      expect(find.text(Translator.translate(AppStrings.academyJourneyContinueLesson)), findsOneWidget);
      expect(find.text(_lessonB.title), findsOneWidget);
    });

    testWidgets('the continue CTA and the highlighted lesson row both fire onContinue', (tester) async {
      var continued = 0;
      await tester.pumpWidget(buildTestable(_stage(state: JourneyStageState.current), onContinue: () => continued++));
      await tester.pump();

      await tester.tap(find.text(Translator.translate(AppStrings.academyJourneyContinueLesson)));
      await tester.tap(find.text(_lessonB.title));
      await tester.pump();

      expect(continued, 2);
    });

    testWidgets('the Pet rides along on the current stage but never takes its tap target', (tester) async {
      await tester.pumpWidget(buildTestable(_stage(state: JourneyStageState.current)));
      await tester.pump();

      expect(find.byType(PetRiveCompanion), findsOneWidget);
      expect(find.ancestor(of: find.byType(PetRiveCompanion), matching: find.byType(IgnorePointer)), findsWidgets);
      expect(find.ancestor(of: find.byType(PetRiveCompanion), matching: find.byType(ExcludeSemantics)), findsWidgets);
    });

    testWidgets('a finished stage compacts to its count plus Mastery, with no CTA and no Pet', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          _stage(state: JourneyStageState.completed, completedLessons: 2),
          isExpanded: false,
          masteryLabel: 'Aplicando',
        ),
      );
      await tester.pump();

      expect(
        find.text(
          '${Translator.translate(AppStrings.academyJourneyStageCompleted, params: {'completed': '2', 'total': '2'})} · Aplicando',
        ),
        findsOneWidget,
      );
      expect(find.text(Translator.translate(AppStrings.academyJourneyContinueLesson)), findsNothing);
      expect(find.byType(PetRiveCompanion), findsNothing);
      expect(find.text(_module.title), findsNothing);
    });

    testWidgets('a future stage is summarised, not unfolded', (tester) async {
      await tester.pumpWidget(buildTestable(_stage(state: JourneyStageState.upcoming), isExpanded: false));
      await tester.pump();

      expect(find.text(_school.title), findsOneWidget);
      expect(
        find.text(Translator.translate(AppStrings.academyJourneyStageTotalLessons, params: {'total': '2'})),
        findsOneWidget,
      );
      expect(find.text(_lessonA.title), findsNothing);
    });

    testWidgets('a locked stage names the prerequisite instead of showing a bare padlock', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          _stage(state: JourneyStageState.locked, missingPrerequisites: const ['Fundamentos']),
          isExpanded: false,
        ),
      );
      await tester.pump();

      expect(
        find.text(Translator.translate(AppStrings.academyLockedPrerequisiteLabel, params: {'name': 'Fundamentos'})),
        findsOneWidget,
      );
    });

    testWidgets('a module row opens that module', (tester) async {
      AcademyModule? opened;
      await tester.pumpWidget(buildTestable(_stage(state: JourneyStageState.upNext), onOpenModule: (m) => opened = m));
      await tester.pump();

      await tester.tap(find.text(_module.title));
      await tester.pump();

      expect(opened?.id, _module.id);
    });

    testWidgets('an expanded stage with no real content says so instead of showing an empty list', (tester) async {
      await tester.pumpWidget(buildTestable(_stage(state: JourneyStageState.comingSoon, withModule: false)));
      await tester.pump();

      expect(find.text(Translator.translate(AppStrings.academyModuleStatusComingSoon)), findsOneWidget);
    });
  });
}
