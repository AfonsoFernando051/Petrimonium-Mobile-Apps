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
├── tooling/          dependency-direction and layering checks
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

`petrimonium_shared_features` declares a dependency on `petrimonium_ui`: its
shared `LoginForm`/`SignupForm` (see "What is deliberately still duplicated"
below) compose `petrimonium_ui` widgets (`CustomTextField`, `GameButton`,
`GameSnack`, `SharedAccountNotice`, `OrDivider`, `GoogleSignInButton`,
`ForgotPasswordButton`), so the declared graph keeps describing what is real.

## Rules that are enforced, not remembered

Four checks run in CI. Three are scripts so that one definition serves both
CI and a developer's terminal.

| Check | Rule |
| --- | --- |
| `tooling/check_dependency_direction.sh` | No package imports an app; no app imports another app |
| `tooling/check_layering.sh` | No `features/*/domain/` file imports Flutter's widget libraries or the data layer |
| `dart format --set-exit-if-changed` | The tree stays formatted |
| `analysis_options.yaml` (root) | One lint baseline; every app and package includes it |

`.github/workflows/architecture.yml` runs the first two **unfiltered**, on
every change. That is deliberate: the dependency-direction check previously
lived only in `shared-checks.yml`, which triggers on `packages/**`, so its
"no app may import another app" rule could never fire on the app-only change
that would break it.

The layering check carries explicit allowlists of the remaining debt, by
path. Removing an entry is the definition of done; adding one needs a reason
in the commit message; a path that no longer exists fails the check so the
allowlist cannot rot into cover for real violations.

A domain layer worth having is one you can test without a widget binding.
That is the whole point of the layering rule, and it is what let
`PortfolioHealthCalculator` move into a package as plain Dart.

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
Gamification: global XP and global level are one number per account, produced
by one backend ledger and read by every product from the same route, so a bug
in the level maths is a bug in all three products at once.

Note the split used for the level tier, because it is the pattern to copy:
the **boundaries** (`level < 5` is a beginner) are ecosystem facts and live in
the package as `LevelTier`; the **label** is product copy and stays in each
app's `LevelTitle`, resolved through its own catalog. Shared structure,
product-supplied copy.

Auth UI: `LoginForm`/`SignupForm` (`lib/src/auth/presentation/`) — see below.

Portfolio (`lib/src/portfolio/`): the entities, the two pure calculators, the
three remote datasources and the three repositories that Academy and Wallet
had byte-identical copies of. Also `PortfolioHealthCalculator`, which is
~90 lines of arithmetic and now carries no Flutter import at all — the
`HealthMetric` it produces names a `HealthMetricKind` instead of a pt-BR
label and an `IconData`, and each app maps that enum to its own copy.

Pet (`lib/src/pet/`): the domain — species, accessories, evolution rules and
stages, profile, animation states. The *companion UI* is not here; see below.

Onboarding DTOs and the Mentor conversation summary round it out.

`lib/testing.dart` is a separate entrypoint carrying test-only builders
(`lot`, `statsFromLots`). It is deliberately off the main barrel so nothing
in a production build imports it by accident, and it lives under `lib/`
because one package cannot import another package's `test/` directory.

### The rules/copy split, and why it keeps recurring

Three extractions here took the same shape, and it is the shape to reach for
first when something "cannot be shared because it has copy in it":

| Shared (ecosystem rule) | Per app (product copy) |
| --- | --- |
| `LevelTier` boundaries | `LevelTitle` catalog |
| `InvestmentTypeRules` — target allocation, assumed yield | `InvestmentTypeDisplay` — label, icon, color |
| `PetSpecieEnum` — wire format, display order | `PetSpecieDisplay.displayLabel` |
| `AchievementRules` — ids, XP, conditions | `AchievementCatalog` — title, description, icon |
| `HealthMetricKind` + the scoring | `HealthMetricDisplay` — label, icon |

The test is whether the two products *must* agree. They must agree about what
a level is worth and what an asset class yields; they need not agree about
what to call it. `AppColors.neonCyan` is the clearest illustration: cyan in
Academy, emerald in Wallet, same field name — which is why anything reading it
is product-branded no matter how identical the source looks.

## What is deliberately still duplicated

Academy and Wallet still hold 51 clone files in `lib/` (~5100 lines) and 52
in `test/` (~4900). That is down from 80 and 93, and what is left is blocked
by three decisions rather than by effort.

**1. The localization mechanism (24 of the 51).** Settings, the Mentor
screens, the auth screens and the Pet's speech all bind to `Translator` and
`AppStrings`, and **the two catalogs have already diverged by roughly 650
lines**. Health is a third system entirely, using ARB files and `gen_l10n`.
Sharing that UI requires first deciding which product's wording wins — a
decision that silently changes one product's copy, which a refactor is not
allowed to do.

Worth naming plainly: **Health already uses the mechanism the other two
should converge on.** `gen_l10n` is the Flutter standard, and the hand-rolled
`Translator` in Academy and Wallet is a 2200-line map each. The convergence
has an obvious destination; it is not a tie to be broken.

**2. Whether `AppEvent` becomes an ecosystem type.** The Pet companion UI
(`pet_rive_companion`, `pet_mascot_widget`, `mascot_controller`,
`pet_speech_bubble*` — about 1400 lines) is i18n-free and looks ready to
share, but `MascotController` listens on `AppEventBus` and `AppEvent` is a
`sealed` hierarchy each app owns. A sealed type cannot be extended from
another library, which is exactly why `ApiClient` reports an expired session
through a callback instead of an event.

Moving `AppEvent` into a package would unblock this *and* let `ApiClient`
emit directly — but it would also make every product's event vocabulary one
shared vocabulary, and Health has no `AppEvent` at all. That is a design
decision, not a mechanical move.

**3. The Academy content-icon chain (9 files).** `AcademyCatalogSnapshot`
deserializes an icon *key* from content JSON straight into a const
`IconData` on the entity, which is why `academy/domain/entities/*` still
import `flutter/material`. Unwinding it means changing the data model's shape
and the seed tooling that writes it
(`tool/generate_academy_seed_json.dart`). Both allowlists in
`tooling/check_layering.sh` enumerate these files by path, so the debt is a
list to work through rather than a number in a report — and a stale entry
fails the check.

A fourth group is duplicated **on purpose** and should stay that way: the
copy catalogs (`AchievementCatalog`, `InvestmentTypeDisplay`,
`MissionDisplayCatalog`, `HealthMetricDisplay`). They read as clones today
because the two products happen to say the same thing; they are the half of
the rules/copy split that each product owns.

Auth was the exception, and is done: verified byte-for-byte identical (or a
single cosmetic line apart) before touching it, so no localization decision
was needed — copy already arrived at each call site via `Translator.translate`
and only had to become a widget parameter instead of an internal call. The six
leaf widgets (`OrDivider`, `GoogleSignInButton`, `ForgotPasswordButton`,
`GameSnack`, plus the already-shared `CustomTextField`/`GameButton`) moved to
`petrimonium_ui`; `LoginForm`/`SignupForm` moved to
`petrimonium_shared_features`, since they own actual state and behavior
(validation, submit, loading) rather than being presentation-only. Each app's
`LoginCard` now supplies copy, an accent color and the callbacks
(`DI.authRepository.login/register/loginWithGoogle`, navigation to `MyApp`,
its own `friendlyErrorMessage`) — no branch on which product is running.

The recommended order for what is left, once the localization decision above
is made:

1. Converge on one shared string mechanism (or agree that shared widgets keep
   taking copy as parameters, which is what the auth extraction and the ten
   widgets before it do and it has worked well).
2. Settings — as a shell plus genuinely common sections, with each app
   injecting its product-specific sections.
3. Mentor and Pet presentation — presentation only. Mentor intelligence rules
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
| `architecture.yml`   | everything — see "Rules that are enforced" above |

A product-only change runs one pipeline plus `architecture.yml`. A
shared-package change runs all five: the package proves itself standing
alone, and each app proves the change did not break it.

## Adding a shared component

1. Ask the decision rule at the top. If only two of three products want it,
   that is usually a sign it belongs to those products for now.
1a. If the answer is "shared, except for the copy", do not stop there — split
   it. The rules go in the package, the wording stays in each app. See the
   rules/copy table above; five components have taken that shape already.
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
