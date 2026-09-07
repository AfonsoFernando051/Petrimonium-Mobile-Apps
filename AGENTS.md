# Petrimonium Mobile — assistant guide

Read the documentation below before changing code. This repository is the
Flutter monorepo for three independently built and released products; it is
not one application with three modes.

## Read first

1. [`docs/PRODUCT_VISION.md`](docs/PRODUCT_VISION.md) — product purpose,
   boundaries and the distinct role of Academy, Wallet and Health.
2. [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md) — repository history,
   documentation ownership and the relationship with the legacy projects.
3. [`docs/ECOSYSTEM.md`](docs/ECOSYSTEM.md) — mobile integration topology and
   ownership boundaries.
4. [`docs/MOBILE_ARCHITECTURE.md`](docs/MOBILE_ARCHITECTURE.md) — current and
   target workspace architecture, dependency direction and extraction rules.
5. [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) — shared visual language,
   product variation and accessibility rules.
6. [`docs/CODING_GUIDELINES.md`](docs/CODING_GUIDELINES.md) — Flutter
   conventions, tests and product-safety checks.
7. [`docs/DECISIONS.md`](docs/DECISIONS.md) — accepted decisions that should
   not be reopened accidentally.

For work inside one app, also read its `README.md` and `docs/` directory.
For Pet or Mentor presentation, read
[`docs/PET_AND_MENTOR.md`](docs/PET_AND_MENTOR.md). For Academy curriculum
work, use the `academy-content` skill and read
[`apps/academy/docs/ACADEMY_CONTENT_AUTHORING.md`](apps/academy/docs/ACADEMY_CONTENT_AUTHORING.md).

The canonical cross-product integration contract is owned by the backend:
[`../Petrimonium-Backend/docs/INTEGRATION.md`](../Petrimonium-Backend/docs/INTEGRATION.md).
Do not redefine its route, JWT, data-isolation or shared-identity rules here.

## Non-negotiable architecture

- Work on `refactor/flutter-monorepo`, never directly on `main`.
- Keep `apps/academy`, `apps/wallet` and `apps/health` independently
  buildable, versioned and releasable.
- Dependency direction is `apps/* -> packages/*`; shared packages never
  import an app and apps never import each other.
- Share screens through composition and configuration. Colors, copy, assets,
  optional sections and callbacks are configuration, not reasons to create a
  base-screen inheritance hierarchy.
- Prefer delegation/Strategy when behavior varies. Use inheritance only for a
  small, stable behavioral contract with a genuine is-a relationship.
- `petrimonium_ui` owns reusable visual primitives;
  `petrimonium_flutter_core` owns genuinely cross-product Flutter
  infrastructure; `petrimonium_shared_features` owns only experience
  structures that are truly shared.
- Shared code must not know product routes, product string catalogs or a
  `Product` enum. Apps inject those details.
- The Spring Boot backend remains the authority for domain rules, account
  identity, access isolation, XP, Pet state and Mentor intelligence. Flutter
  owns client behavior and presentation, not those business rules.
- Rive is an optional presentation adapter. Pet and Mentor abstractions must
  remain usable with other animation technologies or static fallbacks.

## Product boundaries

- Academy uses simulated money for education; it never consumes real Wallet
  or Health financial data.
- Wallet handles real investment patrimony; it does not treat Health cash flow
  as investable balance and does not expose Academy simulations as real data.
- Health handles real cash flow; it does not treat investments as account
  balances and does not perform implicit currency conversion.
- XP rewards learning and approved practice behavior, never wealth, profit,
  portfolio size or a monetary result.
- The Pet represents identity and progress. It never celebrates or punishes a
  financial outcome.
- The Mentor is an educational, context-scoped guide, never an autonomous
  adviser. It must not give deterministic buy/sell/allocation instructions.

## How to change the monorepo

1. Inspect all relevant implementations before extracting anything.
2. Classify code as identical, structurally similar, or only conceptually
   similar. Do not force the third category into a shared abstraction.
3. Ask: "If this is fixed, should all three products receive the fix?"
4. Make the smallest incremental change that preserves each product's copy,
   behavior, navigation and release identity.
5. Test the shared package and every affected app. Use `melos run verify` for
   changes with workspace-wide impact.
6. Update the owning document when architecture or observable behavior
   changes. Mark target behavior explicitly; never present a plan as shipped.

Preserve unrelated user work. Do not use the legacy repositories as current
specifications; they are historical evidence only.
