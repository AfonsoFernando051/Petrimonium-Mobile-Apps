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

Six extractions here took the same shape, and it is the shape to reach for
first when something "cannot be shared because it has copy in it":

| Shared (ecosystem rule) | Per app (product copy) |
| --- | --- |
| `LevelTier` boundaries | `LevelTitle` catalog |
| `InvestmentTypeRules` — target allocation, assumed yield | `InvestmentTypeDisplay` — label, icon, color |
| `PetSpecieEnum` — wire format, display order | `PetSpecieDisplay.displayLabel` |
| `AchievementRules` — ids, XP, conditions | `AchievementCatalog` — title, description, icon |
| `HealthMetricKind` + the scoring | `HealthMetricDisplay` — label, icon |
| `sharedCopy` — wording both products already agreed on | each app's `_productCopy` — its own voice |

The test is whether the two products *must* agree. They must agree about what
a level is worth and what an asset class yields; they need not agree about
what to call it.

The last row adds a third layer the first five did not need. Copy is normally
the product's half — but two products can also simply *agree* on a string, and
1324 of theirs did. So the split is base/override rather than shared/not: the
ecosystem wording is the base, an app declares only what it says differently,
and the override wins. `TranslatorEngine` does the merge; a test in each app
fails if a product override ever repeats a value the base already has, which
is what stops the duplication creeping back one paste at a time.

`AppColors.neonCyan` is the clearest illustration of the other direction: cyan
in Academy, emerald in Wallet, same field name — which is why anything reading
it is product-branded no matter how identical the source looks.

## What is deliberately still duplicated

Academy and Wallet still hold 28 clone files in `lib/` (~3100 lines) and 30
in `test/` (~2800), down from 80 and 93. Every one that is left is behind a
decision or is duplicated on purpose.

Read the line count, not the group count. Extracting a screen leaves a thin
per-app resolver behind — `conversation_list_route`, `level_title`,
`friendly_error_message` — and those are byte-identical between the apps by
their very nature, so they register as clones forever. That is the shape
working, not duplication left behind.

**1. Reaching the translator from a package (9 of the 28).** Counted
honestly, this blocker is nearly spent. The nine break down as:

| | files | status |
| --- | --- | --- |
| Thin per-app resolvers | `level_title`, `friendly_error_message`, `conversation_list_route`, `password_recovery_routes` | by design — these exist *because* the extraction worked |
| The product-copy half | `pet_specie_enum` | by design — the rules half is already shared |
| The app-level resolver | `settings_screen` | by design — it is the thing that owns `Translator` |
| Blocked by `AppEvent`, not by copy | `pet_interaction_sheet`, `pet_companion_header` | both reach `PetCompanionController`, which listens on `AppEventBus` — see 2 |
| Actually ready to move | `pet_comic_speech_bubble` | one copy key, no `AppEvent`; brings three siblings (`pet_message`, `pet_speech_bubble_state`, `pet_speech_bubble_style`) with it |

So only one file is still held up by the translator seam alone. Two more are
really blocker 2 wearing a different hat, and the other six are the pattern
working rather than debt.

Settings was the first slice through this and shows the shape the rest should
take: the seven section widgets take their copy as constructor parameters, the
way `LoginForm` already did, and the screen — which does have a `Translator` —
resolves the keys and passes them in. No new mechanism, no global to
initialise, and a wrong key is a compile error rather than a key rendered raw
on screen. `CompanionSection` is the reason the colour goes the same way:
`AppColors.neonPink` is hot pink in Academy and emerald in Wallet, so it takes
an `accentColor` too.

The cost is that "the section rendered" no longer proves the screen passed it
the right strings, so each app's `settings_screen_test` now asserts the copy
itself. Budget one such test per screen that gets this treatment.

The Mentor conversation history went next and shows the two things Settings
did not need. At fifteen strings the parameter list stops being readable, so
the screen takes a `ConversationListCopy` record instead, built by a per-app
`buildConversationListScreen()` next to the navigation call. And it takes a
`ConversationStore` — three methods — rather than `MentorChatRepository`,
which would have dragged the remote datasource, `ChatMessage`,
`PetPreferencesRepository` and two label-bearing enums into the package with
it. Its backdrop is a parameter too: each app's `CosmicBackground` genuinely
differs, unlike the sections' chrome.

The two password-recovery screens followed the same recipe, and confirmed that
the seam is now routine: a copy record, the product's `LoginBackground` as a
parameter, and the repository reduced to the two calls each screen makes
(`onRequestReset`, `onResetPassword`) — passed as functions, which is what
`LoginForm` had been doing with `onLogin` since the auth extraction.

A rule fell out of these three: a screen extracted this way needs a wiring
test left behind in each app, because nothing else covers the route factory
that resolves its keys. `password_recovery_routes` had no coverage at all for
a moment; `settings_screen_test` had coverage that would have passed with
every key wrong.

The copy itself is no longer in the way. Measured rather than assumed, the two
catalogs held 1377 (language, key) pairs in common and **1324 of them were
already identical** — the real divergence is 18 keys, which is brand voice
(`brandTagline`, `meetPetIntro`, the Academy intro) and nothing else. Those
1324 now live once in `sharedCopy`; each app keeps its 18 overrides plus the
strings for screens the sibling does not have. All of these files are byte-identical
between the apps, so every key they touch is by construction in the shared
452 — none of them needs a wording decision to move.

Two more files only ever wanted the language *code*
(`onboarding_remote_datasource`, `mentor_chat_repository` — `?lang=` and a
`language:` argument). Those take a `String`, not a translator, and are not
part of this blocker at all.

An earlier version of this section claimed the catalogs had "already diverged
by roughly 650 lines" and that converging on `gen_l10n` was the obvious
destination. Both were wrong. The divergence was 18 keys, and `gen_l10n` is
reachable only from a `BuildContext` — while Academy and Wallet translate from
domain and data code (`level_title`, `friendly_error_message`, three
repositories/datasources) where no context exists. Migrating would mean either
pushing `BuildContext` into the domain, which the layering guard now forbids,
or restructuring those callers to return keys. That is an architecture change,
not the mechanical migration the old text implied. `friendlyErrorCopy` and
`levelTierKey` show the way out where it is worth taking: the rule returns a
key, and the product resolves it.

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

**3. The five copy catalogs** — `AchievementCatalog`, `Achievement`,
`InvestmentTypeDisplay`, `MissionDisplayCatalog` and `HealthMetricDisplay` —
are duplicated **on purpose** and should stay that way. They read as clones
today only because the two products happen to say the
same thing; they are the half of the rules/copy split that each product owns,
and the moment one product's wording changes they stop looking alike.

The Academy content-icon chain used to be a fourth blocker. It is resolved:
the catalog entities carry an icon *key* and only presentation resolves it,
so the whole nine-file block moved to `petrimonium_shared_features`. That is
also why `tooling/check_layering.sh`'s widget-library allowlist is empty —
all 21 domain files that imported a Flutter widget library are clean.

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
