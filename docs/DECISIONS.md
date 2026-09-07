# Petrimonium mobile decisions

This file records durable product and mobile-architecture decisions. It is not
a changelog. Historical decisions from `Invest-Game-V2` were consolidated here
only when they still constrain the three-product ecosystem.

## PM-001 — Three products in one mobile monorepo

**Status:** accepted.

Academy, Wallet and Health remain separate installable products with their own
journeys, navigation, assets, native identifiers, versions and releases. They
share one source workspace so genuinely common Flutter code can evolve once.
The monorepo is not a universal application shell.

## PM-002 — Shared UI uses composition and configuration

**Status:** accepted.

Shared screens and structures receive copy, palette, assets, optional sections
and callbacks from the app. Screen inheritance is not the primary reuse
mechanism. Delegation/Strategy is preferred for behavioral variation;
inheritance is limited to small stable behavioral contracts.

## PM-003 — Backend owns domain and ecosystem integration

**Status:** accepted.

Spring Boot remains a separate Clean Architecture system and the authority for
identity, access isolation, financial rules, XP, Pet state and Mentor
intelligence. Flutter owns client orchestration and presentation. The backend's
`docs/INTEGRATION.md` is canonical for cross-product contracts.

## PM-004 — Financial contexts never blur

**Status:** accepted.

Health cash flow and Wallet patrimony are real but answer different questions;
Academy money is simulated. No client convenience may mix them, treat one as
another or bypass backend `app_context` isolation. Academy simulations carry a
persistent fictitious-data marker.

## PM-005 — Academy remains learning-first

**Status:** accepted; inherited from historical decisions 012, 013 and 018–025.

Academy's core loop is Learn -> Practice -> Progress -> Grow. The curriculum
and authoritative progression live in the backend. The mobile app presents the
catalog, short lessons, quizzes, recommendations, review and Financial Lab.
Game level is motivational progression, not certification of knowledge.

## PM-006 — XP never rewards money

**Status:** accepted; inherited from historical decisions 014 and 027.

XP and reward moments derive only from allow-listed learning or approved
practice behavior. Wealth, profit, returns, portfolio size, deposits,
dividends, trades, balances and paid bills are never direct reward sources.
The backend ledger is authoritative.

## PM-007 — One Pet identity, presentation separated from intelligence

**Status:** accepted; inherited from historical decision 015.

The same Pet identity follows the person across products. Pet identity/state,
Mentor intelligence and Pet experience are separate concerns. Flutter may
render and animate the Pet, but the Pet never represents a risk profile or
reacts positively/negatively to a financial outcome.

## PM-008 — Mentor is context-scoped education, not advice

**Status:** accepted; inherited from historical decisions 028 and 036, refined
by the multi-product split.

The backend constructs context-specific prompts and applies safety controls.
The mobile app never receives provider secrets or builds an authoritative
prompt from cross-product data. Mentor presentation supports explanation,
disclosure, loading/error states and safe conversation; it does not convert a
model response into deterministic trading action.

## PM-009 — Academy curriculum is backend-authored

**Status:** accepted; inherited from historical decisions 022 and 025.

Curriculum JSON and stable content identifiers live under
`Petrimonium-Backend/src/main/resources/academy-content/`. The Academy client
fetches and caches presentation data; content-only changes do not require a
Flutter release. Existing domain/school/module/lesson IDs are permanent
because progress and XP reference them.

## PM-010 — Animation technology is replaceable

**Status:** accepted; refined from historical Pet/Rive work.

Rive is an optional adapter for Academy and Wallet, not an ecosystem or package
architecture dependency. Semantic Pet state and Flutter-accessible text are
the stable interfaces. Missing/incompatible animation assets fall back safely
to Lottie/PNG/static presentation.

## PM-011 — Melos 6 preserves independent resolution

**Status:** accepted for the current dependency sets.

The workspace uses Melos 6 path dependencies rather than a Dart Pub workspace.
Current app constraints do not converge cleanly, and one root lockfile would
couple independent release lines. Revisit only when the dependency sets and
release requirements materially change.

## PM-012 — Documentation names current versus target

**Status:** accepted; inherited from historical decision 016.

Architecture documentation must not present a plan as implemented. Historical
repositories explain origin, not current status. Durable mobile facts live in
this repository; backend contracts live in the backend. Product-specific facts
live with the app that owns them.

## Historical aliases still present in source comments

The imported code contains references to the old combined-repository decision
numbers. Until those comments are naturally touched, interpret them as:

| Historical ID | Current authority |
| --- | --- |
| `DECISION-014`, `DECISION-027` | PM-006 — no XP from money or investment activity |
| `DECISION-019`, `DECISION-020`, `DECISION-025` | PM-005/PM-009 and `apps/academy/docs/ACADEMY_ENGINE.md` |
| `DECISION-028`, `DECISION-036` | PM-008 — Mentor context and safety |
| `DECISION-029` | Product Vision §10 — educational, read-only concept bridge |
| `DECISION-030` | `DESIGN_SYSTEM.md` — hierarchy over decoration |
| `DECISION-031`–`DECISION-034` | PM-007/PM-010 and `PET_AND_MENTOR.md` |
| `DECISION-037` | PM-005/PM-006 and Academy Engine §3g — five Financial Lab simulators with backend-authoritative completion/XP |

The original full records remain in `Invest-Game-V2` history. These aliases
preserve meaning without importing obsolete combined-app architecture.
