# Academy — mobile architecture and learning contract

## Product role

Academy is the learning-first Petrimonium product. Its loop is:

```text
Learn -> Practice -> Progress -> Grow
```

Learning progress and game level are distinct. Completion/mastery describes
the curriculum; XP/level is motivational and drives shared Pet progression.
Neither is a certification or financial recommendation.

## Current experience

The app currently presents:

- domains, schools, modules, lessons and typed lesson steps;
- explanation, example, choice-question and summary steps;
- completion, knowledge progress, mastery, review and recommendations;
- five Financial Lab simulators: compound interest, inflation, fixed income,
  diversification and portfolio;
- a simulated wallet backed by Academy-only endpoints;
- Mentor and Pet presentation connected to learning/practice context.

The current primary navigation is Home, Academy, simulated Wallet and Mentor.
Treat this as current implementation, not as a universal shell for other apps.

### 3d. Mastery, recommendations and review

Completion records that a lesson was finished; mastery reflects demonstrated
understanding. Recommendations choose a useful next learning action and review
surfaces material worth revisiting. These signals stay distinct from game
level. Client services may organize the presentation, while persisted progress
and reward authority remain in the backend.

### 3g. Financial Lab

The five simulators share interaction/presentation structure and pure client
calculators for immediate exploration. Each simulator explains assumptions and
keeps a persistent simulation marker. Completion and XP are submitted to the
backend with stable simulator IDs and idempotent authority there.

## Source-of-truth split

| Responsibility | Owner |
| --- | --- |
| Curriculum JSON, stable IDs and localized source content | `Petrimonium-Backend/src/main/resources/academy-content/` |
| Catalog, progress, mastery, XP and simulator-completion authority | Petrimonium Backend |
| API/cache mapping and offline presentation snapshot | Academy data layer |
| Session interaction, question order and local UI orchestration | Academy controllers/services |
| Screens, steps, charts, feedback, accessibility and simulation marker | Academy presentation |

The mobile app may calculate interactive simulator previews so the person can
explore values immediately. Completion and rewards remain backend-authoritative.
Do not move curriculum authority or reward rules into Flutter.

## Client structure

```text
lib/features/academy/
├── data/
│   ├── datasources/       # catalog, learning and lab HTTP calls
│   ├── models/            # API/cache serialization
│   └── repositories/      # catalog and local progress/cache seams
├── domain/
│   ├── entities/          # presentation-facing Academy concepts
│   └── services/          # pure calculators/recommendation helpers
└── presentation/
    ├── controllers/       # catalog, lesson session and completion state
    ├── screens/           # journey, lesson and Financial Lab flows
    └── widgets/           # cards, steps, progress and feedback
```

Extend this structure rather than introducing a parallel Academy architecture.

## 5. UX flow

Academy Home prioritizes continuing the current lesson, then progress,
recommendation/review and practice. A lesson presents short typed steps,
supportive question feedback and an explicit completion result. Locked content
explains prerequisites. Offline/cache behavior may keep reading available, but
must not invent authoritative completion or rewards.

## Backend routes consumed

- `/api/v1/academy/catalog`
- `/api/v1/learning/lessons/{id}/complete`
- `/api/v1/learning/progress`
- `/api/v1/lab/simulators/{id}/complete`
- `/api/v1/lab/simulators/progress`
- `/api/v1/simulated-portfolios/**`

The backend gates these paths with `app_context = academy`. Route/access
details belong to the backend integration contract, not this document.

## 7. Educational Portfolio Intelligence

An Academy concept may be reflected in a Wallet asset view through a stable
concept identifier. This is a one-way educational interpretation bridge, not a
data merge: Academy never receives the real holding, and Wallet does not import
Academy screens. The destination fetches its own allowed data and keeps
product-specific copy/actions local.

## Learning and safety rules

- All practice money is simulated and persistently labelled.
- Explanations teach mechanisms and trade-offs, not what to buy or sell.
- Wrong answers receive neutral, useful feedback and can be retried without
  punishment.
- XP comes only from backend-approved learning/practice events.
- Knowledge progress is not inferred from XP level.
- Tax/legal/time-sensitive claims carry jurisdiction/source verification when
  available and are not silently presented as timeless facts.
- Accessibility includes readable text scaling, semantics, reduced motion and
  textual alternatives for charts.

## Curriculum changes

Do not hardcode new curriculum in Flutter. Use
[`ACADEMY_CONTENT_AUTHORING.md`](ACADEMY_CONTENT_AUTHORING.md) and the
`academy-content` skill. Content-only changes belong to the backend and are
picked up by the client catalog flow without a mobile release.

## Validation

For client changes, run `flutter analyze` and `flutter test` in
`apps/academy`. Run `melos run verify` when shared packages change. For
curriculum changes, use the backend validation described in the authoring
guide.
