# Petrimonium Mobile — workspace architecture

This repository holds the three Petrimonium Flutter products and the packages
they share. The Spring Boot backend is **not** here: it stays in
`Petrimonium-Backend`, with its own lifecycle, and it remains the
authoritative owner of the ecosystem's domain rules.

## The decision rule

Before moving anything into `packages/`, answer one question:

> If we fix or improve this component, should Academy, Wallet **and** Health
> receive the change?

If yes, it is a strong shared-package candidate. If no, it belongs to the
product. Two things looking alike is not an answer — Academy and Wallet were
forked from the same codebase, so a great deal of their code is identical for
historical reasons rather than because it is genuinely one thing.

## Layout

```
petrimonium-mobile/
├── apps/
│   ├── academy/     financial education and learning habits
│   ├── wallet/      portfolio organization, monitoring and analysis
│   └── health/      financial health diagnosis, goals, periodic evolution
├── packages/
│   ├── petrimonium_ui/               design tokens, theming, presentation widgets
│   ├── petrimonium_flutter_core/     environment config, API client, utilities
│   └── petrimonium_shared_features/  features the whole ecosystem shares
├── tooling/
├── docs/
├── .github/workflows/
└── melos.yaml
```

## Dependency rules

```
apps/academy ─┐
apps/wallet  ─┼──> petrimonium_shared_features ──> petrimonium_flutter_core
apps/health  ─┘                                └──> petrimonium_ui
```

Three rules, all enforced by `.github/workflows/shared-checks.yml` rather than
by good intentions:

1. **No package may import an app.** `packages/**` must never contain
   `package:petrimonium_academy/`, `petrimonium_wallet/` or
   `petrimonium_health/`.
2. **No app may import another app.** Academy must not reach into Wallet, and
   so on. Products communicate through the backend and through deep links,
   never through each other's Dart code.
3. **No circular dependencies.** Packages may depend on packages below them
   only.

`petrimonium_shared_features` does not currently declare a dependency on
`petrimonium_ui`, because nothing in it imports UI yet. That edge gets added
when shared UI actually lands, so the declared graph keeps describing what is
real rather than what is planned.

## What belongs in each package

### `petrimonium_ui`

The visual foundation: spacing, radii, motion, typography, the color-token
shape, the theme builder, and presentation-only widgets.

It contains **no product name, no product route, no business rule, and no
string catalog**. Everything product-specific arrives as configuration:

- **Colors** through `PetrimoniumTheme.build(brightness:, colors:, accents:)`.
  Each app owns `lib/core/theme/app_palette.dart`. Academy is cosmic-dark with
  cyan/violet accents; Wallet is petrol-green with emerald, and additionally
  renders a market dip in a neutral tone rather than alarm red — a Wallet
  product guardrail, which is precisely why it lives in Wallet.
- **Copy** through widget parameters. Every shared widget that renders text
  takes that text as an argument.
- **Behavior** through callbacks.

There is no `Product` enum and there must never be one. Adding a fourth
Petrimonium app should require zero edits to this package.

### `petrimonium_flutter_core`

Flutter-level infrastructure that is the same because the *platform and the
backend* are the same: `PetrimoniumEnvironment` (base URL, release guard),
`ApiClient` (single-flight 401 refresh, retry-once, token storage),
`extractErrorDetail`, and three pure utilities.

`ApiClient` reports a definitively-lost session through an `onSessionExpired`
callback rather than emitting an event. Each app's `AppEvent` is a sealed
hierarchy, and a sealed type cannot be extended from another library, so the
bridge is wired at each app's composition root (`DI.notifySessionExpired`).
That callback is optional, so each app carries a test pinning the wire-up —
forgetting it would silently disable logout-on-expiry without failing
anything else.

**Not here:** product business rules. Account, consent, global XP, global
level, Pet evolution, Mentor context, financial calculations, Academy
progression and Health rules are owned by the backend domain. Flutter may
carry DTOs, clients, presentation models, caching and UI behavior for them. It
must not quietly become their source of truth.

### `petrimonium_shared_features`

Features that genuinely belong to the ecosystem rather than to one product.
Today: gamification. Global XP and global level are one number per account,
produced by one backend ledger and read by every product from the same route,
so a bug in the level maths is a bug in all three products at once.

Note the split used for the level tier, because it is the pattern to copy:
the **boundaries** (`level < 5` is a beginner) are ecosystem facts and live in
the package as `LevelTier`; the **label** is product copy and stays in each
app's `LevelTitle`, resolved through its own catalog. Shared structure,
product-supplied copy.

## What is deliberately still duplicated

Academy and Wallet still hold byte-identical copies of the pet (22 files),
settings (11), mentor (8) and auth (8) blocks. This is known, and it is not an
oversight.

All of them are bound to `Translator` and `AppStrings`, and **the two catalogs
have already diverged by roughly 650 lines**. Health is a third system
entirely, using ARB files and `gen_l10n`. Sharing that UI therefore requires
first deciding which product's wording wins for the shared strings — a
decision that silently changes one product's copy, which a refactor is not
allowed to do.

So the prerequisite for the next extraction phase is a **localization
decision, not a refactor**. The recommended order once it is made:

1. Converge on one shared string mechanism (or agree that shared widgets keep
   taking copy as parameters, which is what the ten already-extracted widgets
   do and it has worked well).
2. Auth UI — the layout, fields, validation, loading and error presentation
   are already structurally identical; only copy, accent and post-login
   navigation differ. Those are callbacks and configuration, not branches.
3. Settings — as a shell plus genuinely common sections, with each app
   injecting its product-specific sections.
4. Mentor and Pet presentation — presentation only. Mentor intelligence rules
   stay in the backend, and Rive must remain a replaceable presentation
   technology, not an interface baked into shared widgets.

## Working in this repository

Melos is pinned to the 6.x line on purpose. Melos 7 moved to Dart Pub
workspaces, which force one shared resolution and one root lockfile. That was
tried here and rejected on evidence: `dart pub get` fails outright because
Health is on `google_fonts ^6.2.1` and the other two on `^8.2.1`; a workspace
permits `dependency_overrides` only at the root, so each app's toolchain pins
would become workspace-wide; and a shared lockfile couples the three release
lines. Path dependencies keep every app resolving and locking independently.

```bash
dart pub global activate melos 6.3.2   # once
melos bootstrap                         # resolve every package

melos run analyze                       # flutter analyze everywhere
melos run test                          # every suite
melos run verify                        # analyze + test, what CI runs
melos run format                        # format in place
melos run format-check                  # CI-style check
```

Running one app:

```bash
cd apps/academy && flutter run   # or apps/wallet, apps/health
```

Health additionally needs `flutter gen-l10n` after changing its ARB files.

Release builds, one product at a time:

```bash
melos run build:academy      # or build:wallet / build:health
# equivalently
cd apps/wallet && flutter build appbundle --release
```

A Wallet release does not require building or publishing Academy or Health.

### Versions and release identity

Each app owns its own `version:` and build number in its `pubspec.yaml`, its
own `applicationId`/bundle identifier, its own Android and iOS projects, and
its own committed `pubspec.lock`. The library packages do not commit a
lockfile — the consuming app's lockfile decides what ships.

| App     | applicationId / bundle id            |
| ------- | ------------------------------------ |
| Academy | `com.petrimonium.academy`            |
| Wallet  | `com.petrimonium.wallet`             |
| Health  | `com.petrimonium.petrimonium_health` |

Release signing is supplied at build time through `android/key.properties`,
which is gitignored along with keystores. No signing material, token or `.env`
belongs in this repository.

## CI

| Workflow             | Runs on                                     |
| -------------------- | ------------------------------------------- |
| `academy.yml`        | `apps/academy/**`, `packages/**`, `melos.yaml` |
| `wallet.yml`         | `apps/wallet/**`, `packages/**`, `melos.yaml`  |
| `health.yml`         | `apps/health/**`, `packages/**`, `melos.yaml`  |
| `shared-checks.yml`  | `packages/**`, `melos.yaml`, root `pubspec.yaml` |

A product-only change runs one pipeline. A shared-package change runs all
four: the package proves itself standing alone, and each app proves the change
did not break it.

## Adding a shared component

1. Ask the decision rule at the top. If only two of three products want it,
   that is usually a sign it belongs to those products for now.
2. Put it in the lowest package that can hold it. UI with no logic goes in
   `petrimonium_ui`.
3. Take copy as a parameter. Take colors from `context.colors` /
   `context.brand`. Take behavior as a callback.
4. Give it a test in the package, against the neutral test palette rather than
   any one product's theme. A widget that only renders correctly under one
   product's colors has a bug.
5. Migrate the consumers, run `melos run verify`, and only then delete the
   duplicate implementations.

Shared components have a blast radius of three products. Accessibility
regressions included: preserve semantics, screen-reader labels, touch target
sizes, dynamic text behavior and contrast, because a regression here is a
regression everywhere at once.

## Adding a future Petrimonium application

Create `apps/<product>/` as a normal Flutter app, add path dependencies on the
shared packages, define its own `app_palette.dart`, and add a workflow modeled
on `health.yml`. Nothing in `packages/` should need to change to accommodate
it — if it does, that package is carrying a product assumption it should not
have.
