# Pet and Mentor — mobile presentation contract

## Three separate concerns

The user sees the Pet as the Mentor, but the implementation must keep these
concerns independent:

| Concern | Owner | Examples |
| --- | --- | --- |
| Mentor intelligence | Backend | context selection, system prompt, provider, safety guard |
| Pet identity | Backend | species, name and shared persistent state |
| Pet experience | Flutter apps | visual presenter, bubble, loading/error state, CTA, animation adapter |

This split prevents a Flutter widget or animation file from becoming the home
of financial advice, progression rules or cross-product data access.

## Current state

- Academy and Wallet each have product-local Pet/Mentor implementations. Their
  companion trees are structurally similar but have already diverged in copy,
  message catalogs and behavior.
- Health has its own Pet setup and Mentor presentation architecture.
- Pet/Mentor UI is therefore an extraction candidate, not a shared feature that
  has already been extracted.
- The backend currently supports context-specific Mentor paths for Academy,
  Wallet and Health. Each path can access only its allowed context.

Any shared extraction starts with presentation primitives such as
`MentorScaffold`, `MentorBubble`, `MentorMessage`, `MentorCTA`, loading/error
states and a renderer-neutral `PetPresenter`. Product context, copy and actions
are injected. The shared package never imports app routes or backend prompt
logic.

## Mentor presentation rules

- Present the Mentor as education/reflection, never autonomous advice.
- Preserve the visible "not financial advice" boundary where appropriate.
- Show actionable loading, retry and unavailable states.
- Disclose the sources/reasons returned by the backend for contextual
  interpretations; translate stable source keys in the app.
- Do not send more client context than the request needs.
- Never place provider API keys, system prompts or cross-product financial data
  in the mobile application.
- Generated text does not gain authority by appearing next to the Pet. Do not
  automatically convert it into buy/sell/transfer actions.

## Pet experience rules

- Reactions are semantic presentation events, not financial calculations.
- The Pet may acknowledge learning, approved practice, consistency and direct
  interaction.
- The Pet never celebrates or punishes return, balance, wealth, deposit,
  dividend, trade, bill value or a wrong answer.
- Species is identity, not an investor-risk category.
- A missing or incompatible animation asset must degrade to another presenter,
  never make a screen fail.
- Reduced motion produces a calm stable state.

## Speech bubbles

The useful part of the historical companion bubble design remains valid:
dynamic communication belongs in native Flutter UI, while character animation
may live in an interchangeable renderer.

Reasons:

- Flutter text supports localization and dynamic length;
- semantics and live-region behavior remain available to assistive technology;
- the layout can respond to screen width and text scaling;
- the bubble can be anchored to the Pet independently of the animation format.

Academy and Wallet currently use product-local variants of a comic-style
bubble with semantic visual states, typewriter reveal, tap-to-complete, reduced
motion and anchor-aware placement. Similarity should be extracted only after
the two implementations and Health's needs are compared. Shared state names
must describe communication intent, not a product event catalog.

## Animation boundary

Rive is currently used as an optional adapter in Academy and Wallet, with
Lottie/PNG fallback. It is not used as a shared package contract and must not
become one. Code consumes a semantic animation state; the adapter translates
that state into Rive inputs/artboards when compatible assets exist.

The current authoring contract for optional `.riv` files is documented in
[`RIVE_PET_COMPANION_BRIEF.md`](RIVE_PET_COMPANION_BRIEF.md).

## Extraction test

Before sharing Pet/Mentor UI, verify all of the following:

1. the improvement should apply to Academy, Wallet and Health;
2. copy can be supplied without importing an app localization catalog;
3. the API accepts a renderer/presenter, not a Rive-specific domain type;
4. product sections and actions are composable;
5. no Mentor intelligence or Pet progression rule moved into Flutter UI;
6. accessibility and fallback behavior have package-level tests.
