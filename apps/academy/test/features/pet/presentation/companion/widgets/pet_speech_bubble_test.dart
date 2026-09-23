import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium_academy/core/theme/app_theme.dart';
import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/pet_companion_controller.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/widgets/pet_speech_bubble.dart';
import 'package:petrimonium_academy/features/pet/presentation/mascot/controllers/mascot_controller.dart';

/// Minimal in-memory MascotRepository double, mirrors the one used in
/// `mascot_controller_test.dart` — only `loadProfile` matters here.
class FakeMascotRepository implements MascotRepository {
  PetProfile profileToReturn = PetProfile();

  @override
  Future<PetProfile> loadProfile() async => profileToReturn;
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

void main() {
  late FakeMascotRepository mascotRepository;
  late MascotController mascotController;
  late PetCompanionController companionController;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    mascotRepository = FakeMascotRepository();
    mascotController = MascotController(repository: mascotRepository);
    companionController = PetCompanionController(mascotController: mascotController);
  });

  // Not a plain tearDown(): PetCompanionController._show starts a real
  // Timer (auto-hide) and MascotController.triggerEventAnimation starts
  // another (revert-to-resting) whenever a message is shown — both are
  // cancelled by their owner's dispose(), but flutter_test's "no pending
  // Timer" invariant check runs before a package:test tearDown() callback
  // would fire, so each test below disposes explicitly at the end instead.

  Widget buildTestableWidget({ValueChanged<PetMessageAction>? onActionSelected}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: PetSpeechBubbleOverlay(controller: companionController, onActionSelected: onActionSelected),
      ),
    );
  }

  group('PetSpeechBubbleOverlay', () {
    testWidgets('desktop bubble stays below the toolbar and inside the viewport', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final anchor = PetSpeechBubbleAnchor();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 40,
                  top: 160,
                  child: CompositedTransformTarget(
                    link: anchor.link,
                    child: SizedBox(key: anchor.boxKey, width: 80, height: 80),
                  ),
                ),
                PetSpeechBubbleOverlay(controller: companionController, anchor: anchor),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      companionController.enterContext(
        PetContext.home,
        data: {'lessonTitle': 'Uma aula longa para entender como organizar sua vida financeira'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final bubble = tester.getRect(find.byType(PetComicSpeechBubble));
      expect(bubble.top, greaterThanOrEqualTo(kToolbarHeight));
      expect(bubble.left, greaterThanOrEqualTo(16));
      expect(bubble.right, lessThanOrEqualTo(1264));
      expect(bubble.bottom, lessThanOrEqualTo(640));
      companionController.dispose();
      mascotController.dispose();
    });

    // The bubble lives in the root Overlay so it paints above the AppBar —
    // which also put it above every route pushed on top of the host. That is
    // how the companion ended up covering the question stem on the lesson
    // screen while the student was trying to read it.
    testWidgets('hides while another route covers the screen that owns it', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          navigatorKey: navigatorKey,
          home: Scaffold(body: PetSpeechBubbleOverlay(controller: companionController)),
        ),
      );
      await tester.pump();
      companionController.enterContext(PetContext.home, data: {'lessonTitle': 'Vida Financeira'});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PetComicSpeechBubble), findsOneWidget);

      unawaited(
        navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Aula')))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aula'), findsOneWidget);
      expect(find.byType(PetComicSpeechBubble), findsNothing);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(find.byType(PetComicSpeechBubble), findsOneWidget);

      companionController.dispose();
      mascotController.dispose();
    });

    // On Home the companion's message is already printed inside
    // HomeCompanionCard, so the floating bubble repeated it word for word
    // while sitting on top of the "Continue aprendendo" CTA underneath.
    testWidgets('renders nothing while the host says the message is shown inline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: PetSpeechBubbleOverlay(controller: companionController, isMessageShownInline: true)),
        ),
      );
      await tester.pump();
      companionController.enterContext(PetContext.home, data: {'lessonTitle': 'Vida Financeira'});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PetComicSpeechBubble), findsNothing);

      companionController.dispose();
      mascotController.dispose();
    });

    // The overlay rebuilds on its host route's transition animation, which
    // ticks independently of the controller. Switching language rebuilds the
    // app from the root and can dispose the controller's owner while a
    // pushed screen still holds this overlay — the next tick then tried to
    // subscribe to a dead ChangeNotifier and threw a red screen over Perfil.
    testWidgets('survives its controller being disposed underneath it', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          navigatorKey: navigatorKey,
          home: Scaffold(body: PetSpeechBubbleOverlay(controller: companionController)),
        ),
      );
      await tester.pump();
      companionController.enterContext(PetContext.home, data: {'lessonTitle': 'Vida Financeira'});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PetComicSpeechBubble), findsOneWidget);

      companionController.dispose();

      unawaited(
        navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Perfil')))),
      );
      await tester.pumpAndSettle();
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      mascotController.dispose();
    });

    testWidgets('renders nothing when there is no current message', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(PetSpeechBubbleOverlay), findsOneWidget);
      expect(find.byKey(const ValueKey('empty')), findsOneWidget);

      companionController.dispose();
      mascotController.dispose();
    });

    testWidgets('shows the current message text once one is offered', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Level 1->2 needs 50 total XP; 30 is 60% of the way there — matches
      // PetMessageCatalog's home nudge threshold.
      mascotRepository.profileToReturn = PetProfile(xp: 30);
      await mascotController.loadProfile();
      companionController.enterContext(PetContext.home);
      await tester.pump();
      // AnimatedSwitcher's fade/slide transition (220ms) — bounded pump,
      // never pumpAndSettle (the mascot avatar isn't hosted here, but this
      // keeps the same convention as every other companion widget test).
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Faltam 20 XP para o próximo nível!'), findsOneWidget);

      companionController.dispose();
      mascotController.dispose();
    });

    testWidgets('tapping the action invokes onActionSelected and dismisses the message', (tester) async {
      PetMessageAction? tappedAction;
      await tester.pumpWidget(buildTestableWidget(onActionSelected: (a) => tappedAction = a));
      await tester.pump();

      mascotRepository.profileToReturn = PetProfile(xp: 30);
      await mascotController.loadProfile();
      companionController.enterContext(PetContext.home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Ver Progresso'), findsOneWidget);
      await tester.tap(find.text('Ver Progresso'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tappedAction?.destination, PetContext.profile);
      expect(companionController.currentMessage, isNull);

      companionController.dispose();
      mascotController.dispose();
    });

    testWidgets('tapping the dismiss (close) button clears the current message', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      mascotRepository.profileToReturn = PetProfile(xp: 30);
      await mascotController.loadProfile();
      companionController.enterContext(PetContext.home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(companionController.currentMessage, isNotNull);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(companionController.currentMessage, isNull);

      companionController.dispose();
      mascotController.dispose();
    });
  });

  group('PetSpeechBubbleOverlay — anchored to the Pet', () {
    ComicBubblePainter painterOf(WidgetTester tester) {
      final finder = find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is ComicBubblePainter);
      return tester.widget<CustomPaint>(finder).painter as ComicBubblePainter;
    }

    // A small stand-in for a Pet visual (`PetCompanionHeader`'s avatar or
    // `HomeCompanionCard`'s art) registered as the anchor, plus the overlay,
    // both inside one Stack — mirrors how `DashboardScreen`/`ProfileScreen`
    // actually compose them.
    Widget buildAnchoredWidget({required PetSpeechBubbleAnchor anchor, required Alignment anchorAlignment}) {
      return MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Stack(
            children: [
              Align(
                alignment: anchorAlignment,
                child: CompositedTransformTarget(
                  link: anchor.link,
                  child: SizedBox(key: anchor.boxKey, width: 40, height: 40),
                ),
              ),
              Positioned.fill(
                child: PetSpeechBubbleOverlay(controller: companionController, anchor: anchor),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('anchor near the top of the screen places the bubble below it, tail pointing up', (tester) async {
      final anchor = PetSpeechBubbleAnchor();
      await tester.pumpWidget(buildAnchoredWidget(anchor: anchor, anchorAlignment: Alignment.topLeft));
      await tester.pump();

      mascotRepository.profileToReturn = PetProfile(xp: 30);
      await mascotController.loadProfile();
      companionController.enterContext(PetContext.home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // The header avatar sits right at the top of the screen (inside the
      // AppBar in production) — there's no room to place the bubble above
      // it, so it must fall below with an upward tail (brief §17/§19: never
      // push content off the top of the viewport).
      expect(painterOf(tester).tailPosition, PetBubbleTailPosition.topLeft);

      companionController.dispose();
      mascotController.dispose();
    });

    testWidgets('a centered mid-screen anchor places the bubble above it, tail pointing down', (tester) async {
      final anchor = PetSpeechBubbleAnchor();
      await tester.pumpWidget(buildAnchoredWidget(anchor: anchor, anchorAlignment: Alignment.center));
      await tester.pump();

      mascotRepository.profileToReturn = PetProfile(xp: 30);
      await mascotController.loadProfile();
      companionController.enterContext(PetContext.home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Mirrors `HomeCompanionCard`'s pet, centered with plenty of room
      // above it — the comic convention the design doc calls for: bubble
      // above, tail pointing down at the speaker.
      expect(painterOf(tester).tailPosition, PetBubbleTailPosition.bottomCenter);

      companionController.dispose();
      mascotController.dispose();
    });
  });
}
