# Petrimonium mobile coding guidelines

## Scope

These rules apply to the Flutter monorepo. Backend Java conventions and domain
implementation rules belong to `Petrimonium-Backend` and are intentionally not
duplicated here.

## Before changing code

- Read `AGENTS.md`, the root architecture docs and the affected app docs.
- Inspect every relevant app before extracting shared code.
- Check `git status` and preserve unrelated work.
- Distinguish current behavior from a target described in documentation.

## Structure and dependencies

- Apps may depend on packages; packages never depend on apps.
- Apps never import another app.
- Put a component in the lowest package that can own it without product
  knowledge.
- Avoid barrel exports for app-internal implementation details. Shared package
  public APIs should be deliberate and small.
- Do not add a package dependency for a hypothetical future use.
- Keep each app's native projects, version, assets, lockfile and release
  configuration independent.

## Flutter architecture

- Keep presentation, state orchestration, domain-facing models/contracts and
  data access separated according to the conventions already used by the
  affected app. Do not introduce a parallel architecture during a feature edit.
- Widgets render state and emit intent. HTTP calls and non-trivial rules do not
  live in `build` methods.
- Prefer immutable values and explicit constructors.
- Prefer composition for UI reuse and delegation/Strategy for variable
  behavior.
- Use inheritance only for stable behavioral contracts, adapters or framework
  infrastructure. Keep hierarchies shallow.
- Dispose controllers, focus nodes, subscriptions and animation resources.
- Handle async lifecycle safely (`mounted`, cancellation or ownership as
  appropriate).

## Shared APIs

A shared widget or service must not import:

- an app package;
- an app route;
- an app localization catalog;
- product-specific assets or business rules.

Pass copy, colors, illustrations, optional sections and actions through
configuration. Do not add a `Product` enum to switch behavior inside a shared
package. If branching grows, the abstraction boundary is probably wrong.

## Localization

Academy and Wallet currently use their existing catalog/translator approach;
Health uses ARB and `gen_l10n`. Shared widgets receive already-localized copy
as parameters. Converging localization mechanisms is a separate architectural
decision and must not be smuggled into a component extraction.

## Network and state

- Use the existing client/repository seam. Do not call the backend directly
  from widgets.
- `API_BASE_URL` is supplied with `--dart-define`; release builds must retain
  the localhost guard.
- Each app sends its fixed `app_context`. It is product identity, not a runtime
  flavor or user-selectable setting.
- Treat authentication expiry as an app-composition concern. Shared
  infrastructure reports it through a contract/callback; the app decides
  navigation and user-visible copy.
- Preserve backend error detail only when safe and useful; provide actionable
  loading, empty and retry states.

## Financial and reward safety

- Use typed/parsing boundaries and avoid floating-point assumptions for money.
  Formatting is presentation; it must not alter domain meaning.
- Do not duplicate backend financial formulas as a second source of truth.
  Client calculations used for previews must be labelled and tested.
- Never mix Health cash flow, Wallet patrimony and Academy simulated values.
- Never grant or visually imply XP from wealth, profit, portfolio size or a
  monetary result.
- Never trigger Pet celebration/punishment from market movement, contribution,
  dividend, trade, balance or bill value.
- Mentor UI must preserve educational disclaimers and must not turn generated
  text into a privileged action without a reviewed product decision.

## Accessibility and UI

- Use semantic labels and roles for custom controls and non-text visuals.
- Support text scaling, keyboard/focus navigation where relevant and reduced
  motion.
- Avoid color-only status communication.
- Test shared widgets under a neutral theme, not only one product palette.
- Preserve product-specific copy and navigation during refactors.

## Tests and validation

Match validation to impact:

```bash
# One app
cd apps/<product>
flutter analyze
flutter test

# One package
cd packages/<package>
flutter analyze
flutter test

# Shared or workspace-wide changes
melos run verify
melos run format-check
```

Health additionally needs `flutter gen-l10n` after ARB changes. Add focused
tests for changed behavior and regression tests for fixed bugs. A shared change
must validate every consuming app, not only the package.

## Documentation

Update documentation in the same change when you alter a stable contract,
package responsibility, product boundary, public configuration or run/release
workflow. Avoid chronological changelog prose in architecture documents; Git
already owns history. Record durable trade-offs in `docs/DECISIONS.md`.
