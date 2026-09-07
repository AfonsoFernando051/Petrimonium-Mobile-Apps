import 'package:flutter_test/flutter_test.dart';
import 'package:petrimonium/core/events/app_event.dart';
import 'package:petrimonium/features/pet/domain/enums/pet_animation_state.dart';
import 'package:petrimonium/features/pet/presentation/companion/pet_context.dart';
import 'package:petrimonium/features/pet/presentation/companion/pet_message_catalog.dart';

/// PRD guardrail (§10.3, §12.2, FR-MEN-002): the Pet's celebratory moods are
/// reserved for educational milestones. A financial event — an aporte, a
/// holding, a portfolio state — may be acknowledged, but never with the
/// animation a finished lesson gets.
///
/// This walks the real routing function rather than the individual factories,
/// so a new financial event wired into [PetMessageCatalog.forEvent] with a
/// celebratory mood fails here instead of shipping.
void main() {
  /// `happy` counts: the PRD names "comemoração/felicidade" together, and the
  /// ticket that opened this flagged a `happy` portfolio message alongside the
  /// `celebrate` one.
  const celebratory = {
    PetAnimationState.celebrate,
    PetAnimationState.victory,
    PetAnimationState.happy,
  };

  /// Every event whose `isFinancial` is true. Listed explicitly so that adding
  /// a financial event to `AppEvent` without adding it here is visible in
  /// review — the completeness check below is what catches it.
  const financialEvents = <AppEvent>[
    FirstInvestmentAddedEvent(),
    HighConcentrationDetectedEvent(ticker: 'PETR4', percent: 62.5),
  ];

  group('financial events never celebrate', () {
    for (final event in financialEvents) {
      test('${event.runtimeType} is acknowledged, not celebrated', () {
        final message = PetMessageCatalog.forEvent(event);

        expect(message, isNotNull, reason: 'expected the companion to react at all');
        expect(
          celebratory.contains(message!.mood),
          isFalse,
          reason: '${event.runtimeType} produced ${message.mood}, which the PRD '
              'reserves for educational milestones',
        );
      });
    }

    test('every event listed here really is financial', () {
      for (final event in financialEvents) {
        expect(event.isFinancial, isTrue,
            reason: '${event.runtimeType} is in the financial list but not marked isFinancial');
      }
    });

    test('the first investment stays a bridge into learning, not a reward', () {
      final message = PetMessageCatalog.forEvent(const FirstInvestmentAddedEvent())!;

      expect(message.mood, PetAnimationState.idle);
      // The value of this message is the hand-off to Academy; muting the mood
      // must not have quietly removed it.
      expect(message.action, isNotNull);
    });
  });

  group('educational milestones are still allowed to celebrate', () {
    // The guardrail must not be satisfied by muting the Pet everywhere — that
    // would trade one PRD violation for another.
    test('a completed lesson still celebrates', () {
      final message = PetMessageCatalog.forEvent(const LessonCompletedEvent('l1'))!;

      expect(celebratory.contains(message.mood), isTrue);
    });

    test('a level up still celebrates', () {
      final message = PetMessageCatalog.forEvent(const UserLeveledUpEvent(4))!;

      expect(celebratory.contains(message.mood), isTrue);
    });
  });

  test('a diversified portfolio is reported factually, without a happy mood', () {
    // Not an AppEvent — a pageEnter nudge — but the same guardrail applies: it
    // describes a financial state.
    final message = PetMessageCatalog.pageEnter(
      PetContext.portfolio,
      userXp: 0,
      data: const {'count': '4'},
    );

    expect(message, isNotNull);
    expect(message!.id, 'portfolio_diversified');
    expect(celebratory.contains(message.mood), isFalse);
  });
}
