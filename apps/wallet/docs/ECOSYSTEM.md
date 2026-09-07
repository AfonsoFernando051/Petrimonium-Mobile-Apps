# Ecosystem role — Petrimonium Wallet

> **Where the integration contract lives.** This file is history — the audit
> trail of how this repo got here, update by update. What the ecosystem *is*
> today, and what this app may and may not do at the boundary, is one document
> in one place:
>
> **➜ [`Petrimonium-Backend/docs/INTEGRATION.md`](../../Petrimonium-Backend/docs/INTEGRATION.md)**
>
> Three products (Health, Wallet, Academy), one backend, four shared things
> (identity, Pet, XP ledger, Mentor) and nothing else. Where this file and that
> one disagree, that one wins.

Status as of 2026-08-31: the audit below is historical context from a prior
session and is largely still accurate, but two things have since changed —
see "Update, 2026-08-31 (split execution begins)" at the bottom for what's
actually been decided and implemented. The rest of this file is kept as-is
for the reasoning trail.

Original status note (superseded, kept for history): "audited only — no code
changed yet." A prior Claude Code session ran the repo's onboarding prompt,
produced the audit and findings below, and ended without the user responding
— nothing here had been confirmed or implemented at that point.

## Notion

Project workspace: [Petrimonium](https://app.notion.com/p/3d08bfdad90780c3a935c0054a11770d)
— product docs, the Atlas Técnico (what the system *is*, today, read by
architecture slice) and the Demandas/Correção de Bugs boards findings from
work here should be tracked against.

## The four repos

| Repo | The question it answers | Money |
|---|---|---|
| **`petrimonium-wallet`** (this repo) | *How is my patrimony, and what is it doing?* — trust-forward, behavior-based gamification only | Real (patrimony) |
| [`petrimonium-health`](../../Petrimonium-Health) | *How is my month, and what's left after the commitments I already know about?* | Real (cash flow) |
| [`petrimonium-academy`](../../Petrimonium-Academy) | *Do I understand what I'm doing?* — education, simulated money, full gamification | Simulated only |
| [`petrimonium-backend`](../../Petrimonium-Backend) | Shared Spring Boot / PostgreSQL backend for all three apps, and the only place the boundary between them is enforced | N/A (data layer) |

Cash flow comes before patrimony, and education runs through both — that
ordering is why these are three products and not three tabs. Wallet's own
boundary obligations: never treat Health's cash flow as investable balance,
never surface simulated money, and never let the Pet celebrate an aporte,
a gain, a dividend or a wealth threshold (`INTEGRATION.md` §5.2).

## Where this actually came from

This repo is currently **not** the real-money-only Wallet app its prompt
describes — it's a full clone of [`Invest-Game-V2`](../../Invest-Game-V2), the
same mature combined app (education + simulated portfolio + real portfolio +
gamification + AI mentor + Pet, all one product) that `petrimonium-academy`
was also forked from. Its own code comments cite
`Invest-Game-V2/docs/PRODUCT_VISION.md`/`DECISIONS.md` directly. There is no
`petrimonium-academy`-shaped split here yet, and the backend is referred to
in comments as a single `PetApp-Backend`, not the scoped BFF architecture the
backend prompt targets.

**Practically:** `petrimonium-academy` has since started splitting itself out
of this same shared starting point (nav shell mapping, an isolated Pet
behavior contract, a Wallet-bridge CTA — see that repo's own
`docs/ECOSYSTEM.md`). This repo hasn't done any of that yet — it's still at
the "here's what would need to change" stage.

## Audit findings (§0 of the original prompt)

- **Structure**: feature-first Flutter app — `lib/features/` has `academy`,
  `asset_details`, `auth`, `dashboard`, `game`, `home`, `investment`,
  `mentor`, `onboarding`, `pet`, `portfolio`, `profile`, `settings` — one
  static DI locator, one 5-tab dashboard (Home, Carteira/Wallet,
  Proventos, Academia, Mentor).
- **Academy content is not leftover — it's the product.** The entire
  `lib/features/academy/` tree (schools, modules, lessons, quizzes,
  Financial Lab simulators) is core, intentional, per
  `PRODUCT_VISION.md §6/§10` ("the learning ↔ portfolio connection is the
  deeper, harder-to-copy differentiator"). Stripping it out as "Academy
  leakage" would delete the actual product, not clean up debris — this needs
  a product decision (does Wallet actually lose Academy, or does it stay
  until a real split date?), not an engineering cleanup pass.
- **Gamification — mostly already compliant, three flags:** XP/Pet evolution
  is already hard-gated to learning/practice only (never wealth or trading —
  every outcome-based achievement sets `xpReward: 0` per `DECISION-014`/
  `DECISION-027`). No leaderboard exists anywhere in the codebase. But three
  **0-XP badges are still outcome-based under this repo's own hard rule**
  (§1.3: "never allowed, under any framing... anything that could read as
  comparing investment performance"):
  - `positive_return` ("Primeiro Lucro") — profit-threshold badge
  - `portfolio_10k` / `portfolio_50k` — wealth-threshold badges
  - `dividend_hunter` — passive-income-threshold badge

  All four live in `lib/features/portfolio/domain/services/achievement_catalog.dart`.
  **Open question, never answered:** zero these four out of the catalog, or
  keep them as "flavor" per the existing `DECISION-014` reasoning? This is
  the one concrete, low-risk, non-destructive change available today — it
  just needs your call.
- **Streak naming ambiguity**: `GamificationSummary.currentStreak`/
  `longestStreak` is a general engagement streak (not trade frequency), but
  the field name alone doesn't make that legible to a future contributor,
  and `rpg_integration_card.dart` surfaces it right next to net worth. Worth
  a rename/doc comment, not urgent.
- **State management**: no dedicated library (no Provider/Riverpod/Bloc/GetX)
  — vanilla `ChangeNotifier` controllers + a static-class DI locator, same
  pattern as `petrimonium-academy`.
- **Compliance/KYC**: none exists. No KYC flow, no risk-disclosure copy. Auth
  is a plain access/refresh JWT bearer pair with no `app_context` or
  `provisioning` claim.

## Findings on the remaining tasks (2–6 of the original prompt)

- **Nav shell (task 2)** — proposed mapping if/when Wallet becomes its own
  surface: Overview ← `portfolio`; Invest/Move ← `investment`; Insights ←
  `mentor` + `portfolio/insights` + `asset_details` (drop education content,
  keep the data); Profile/Pet ← `pet` + `profile` + `settings`. `academy`
  has no destination tab in this mapping — it would need to move to a
  separate module/repo entirely, not just a folder rename.
- **Shared packages (task 3)** — zero shared-package infrastructure exists
  (no Melos/workspace, no git-ref packages). Recommendation: defer real
  package extraction until Academy is actually being pulled out of this
  shared starting point; treat `lib/core/*` as the de facto contract to
  duplicate/match until then. Not decided — flagged as your call in the
  original session, still open.
- **`WalletPetBehavior` (task 4)** — **already satisfied structurally, no
  code needed yet.** The single `pet_message_catalog.dart` every reaction
  routes through already takes only pre-aggregated signals (holding counts,
  concentration %, titles) — never raw price/quote data —
  `MascotController.evaluateEvolution` only ever takes `userXp`. The "never
  wire price data into Pet reactions" constraint is already true by
  construction (`DECISION-014`/`DECISION-027`). Writing a
  `WalletPetBehavior implements PetBehavior` today, with nothing else
  implementing the interface, would be a disconnected, unused type — the
  real split only makes sense once Academy extraction is actually underway.
  Compare `petrimonium-academy`'s `PetBehavior` contract
  (`docs/ECOSYSTEM.md` there) once that happens — the two should match.
- **"Learn why" deep link (task 5)** — **already built, more deeply, in-app.**
  `lib/features/asset_details/domain/services/portfolio_learning_bridge.dart`
  already connects completed Academy lessons to live asset indicators
  (`AppliedConcept`), surfaced on the asset-details screen — this is
  `ACADEMY_ENGINE.md §7`'s "Educational Portfolio Intelligence" feature.
  Since Academy and Wallet are the same app today, there's no
  app-not-installed case yet, so building a `petrimonium://` URI resolver
  now would just be unused App Store fallback logic. Proposed scheme name
  for later: `petrimonium://academy/lesson/{id}` — matches the inverse
  direction of `petrimonium-academy`'s own proposed
  `petrimonium://wallet/portfolio?highlight=<concept>` scheme (see that
  repo's `docs/CROSS_REPO_CONTRACTS.md`). Neither scheme is implemented as a
  real OS-level link yet in either repo.

### Task 6 — gamification design-review table

| Element | Type | Verdict |
|---|---|---|
| XP from lessons/quizzes/labs | Behavior-based | ✅ Keep |
| Pet evolution (XP-gated only) | Behavior-based | ✅ Keep |
| Engagement streak (`currentStreak`, daily activity) | Behavior-based | ✅ Keep — rename/re-document so "not trade frequency" is obvious to future contributors |
| `diversification_master`, `etf_collector` badges (0 XP) | Behavior-based | ✅ Keep |
| `first_investment`, `hundred_days`, `long_term_investor` badges (0 XP) | Behavior-based (consistency/milestone) | ✅ Keep |
| `positive_return` ("Primeiro Lucro") badge | **Outcome-based** (profit) | 🚩 Flag — unresolved, see above |
| `portfolio_10k` / `portfolio_50k` badges | **Outcome-based** (wealth threshold) | 🚩 Flag — unresolved |
| `dividend_hunter` badge | **Outcome-based** (passive income threshold) | 🚩 Flag — unresolved |
| Leaderboards | N/A | ✅ None exist in the codebase |
| Streaks tied to trades | N/A | ✅ None exist — streak is engagement-only |

## What hasn't been done

Everything except the audit and the two items below. No nav shell change, no
shared packages, no `WalletPetBehavior`, no deep-link scheme implementation.

## Update, 2026-08-31 (split execution begins)

The user confirmed the full functional split described in the three repos'
prompts is happening now, following a 7-stage incremental plan (baseline
contracts → backend `simulated_portfolio` → Academy migration → backend
`real_portfolio` → Wallet shell → pet/XP/mentor → cleanup). Two decisions
from the original audit above are now resolved:

- **The three/four outcome-based badges** (`positive_return`,
  `portfolio_10k`, `portfolio_50k`, `dividend_hunter` in
  `achievement_catalog.dart`) — **kept as-is for now**, explicitly recorded
  as known technical debt against this repo's own rule that reactions must
  never celebrate wealth. Not blocking the rest of the split. Revisit when
  the Wallet shell (stage 5 of the plan) is actually rebuilt.
- **`app_context` JWT wiring** — implemented. This repo's login/Google-login
  calls (`lib/features/auth/data/datasources/auth_remote_datasource.dart`)
  now send `appContext: 'wallet'` (`ApiConstants.appContext`), matching the
  backend's `AppContextEnum` and the `hasAuthority("APP_CONTEXT_WALLET")`
  gate the backend already enforces on `/api/investments/**` (backend commit
  `7b51782`). Before this fix, this app's investment endpoints were already
  returning 403 against that backend version — this was a live regression,
  not a preventive change. Covered by
  `test/core/constants/api_constants_test.dart` (asserts the constant is
  exactly `'wallet'`, never `'academy'`) and the updated
  `auth_remote_datasource_test.dart`.

Everything else above (nav shell, shared packages, `WalletPetBehavior`,
deep-link scheme, task 2/3/4/5 findings) is unchanged and still pending —
tracked under the plan's later stages.

## Update, 2026-08-31 (Stage 5 — Wallet shell, first pass)

Stage 5 of the plan (own navigation shell, strip Academy/educational
gamification surfacing) executed as a **first pass**, scoped to the
highest-risk, most user-facing pieces rather than a full sweep of every
Academy reference in the codebase (that full sweep — deleting
`lib/features/academy/`, the old `home_screen.dart`, `academy_intro_screen.dart`,
`gamification_intro_screen.dart`, mission catalog/data files, and
`next_action_card`/`knowledge_map_strip`/`learning_hero_card`/
`portfolio_bridge_card` — is deliberately deferred to Stage 7, matching the
"don't move hundreds of files in one pass" precedent from earlier stages).

What changed:

- **Onboarding wizard no longer routes new signups through Academy/
  gamification intro screens.** This was a live product/compliance issue,
  not dead code: every new Wallet user (a real-money app) was being shown
  `AcademyIntroScreen`/`GamificationIntroScreen`. `pet_configuration_screen.dart`
  now navigates straight to `FinancialGoalScreen`. Confirmed via grep that no
  other entry point (`main.dart`, route resolver) reaches the skipped
  screens, so they're safely unreachable without needing deletion yet.
- **Dashboard shell has no Academy tab.** `DashboardTabRouter` rewritten:
  `academyTab` removed, remaining tabs renumbered
  (`homeTab=0, walletTab=1, passiveIncomeTab=2, mentorTab=3`),
  `petContextFor` no longer maps any tab to `PetContext.academy`.
  `DashboardScreen`'s `IndexedStack` dropped `_buildAcademyContent()`
  entirely. The persistent pet companion's "go to Academy" destination
  (`PetContext.academy`, still reachable from non-tab UI) now shows a
  "coming soon" snackbar instead of switching tabs, since Academy is a
  separate app now — no in-app fallback exists.
- **New Home tab (`OverviewScreen`)** replaces the old Academy-heavy
  `HomeScreen`: portfolio hero summary, wealth evolution, insights, and an
  `AcademyBridgeCta` (mirrors Academy's own `WalletBridgeCta`) that always
  renders in a disabled/"coming soon" state, since cross-app deep-linking
  isn't implemented in either direction yet.
- **`MissionsSection` removed from `PortfolioScreen`.** Missions are an
  educational-gamification concept (daily/weekly lesson-completion
  quests) that has no place in the real-money Carteira view.
  `AchievementsSection` (behavior-based badges, see Task 6 table above) is
  kept.

Tests: fixed 3 tests that broke as direct, expected consequences of the
above (onboarding nav target assertion, the now-removed Academy-tab nav
test, the now-removed MissionsSection-visible test) — no other tests
touched. Full suite: 1584/1584 green. `flutter analyze`: no issues.
`flutter build linux --debug`: succeeds.

Not done in this pass (tracked as Stage 7 debt): full deletion of
`lib/features/academy/`, the old `home_screen.dart`, `academy_intro_screen.dart`
and `gamification_intro_screen.dart` files themselves (now unreachable but
still present), mission catalog/data-layer files, and the outcome-based
badges flagged as debt back in the original audit (`positive_return`,
`portfolio_10k`, `portfolio_50k`, `dividend_hunter`) — still un-migrated per
the earlier "keep as-is for now" decision.

No commits yet for this stage's changes — pending the end-of-stage report.

## Update, 2026-08-31 (Stage 7 — dead-code cleanup, first pass)

Deleted the code Stage 5 deliberately left in place but made unreachable:

- `lib/features/academy/` — 57 of 66 files removed (screens, controllers,
  Financial Lab, calculators, widgets). Kept 9 files that are a genuine
  live dependency of the asset-details "Educational Portfolio
  Intelligence" bridge (`asset_details_controller.dart` → `PortfolioLearningBridge`
  → `AcademyCatalogRepository`/`AcademyProgressLocalRepository` and the
  catalog domain models they return): `academy_catalog_repository.dart`,
  `academy_progress_local_repository.dart`, `academy_catalog_snapshot.dart`,
  `lesson.dart`, `lesson_step.dart`, `academy_domain.dart`,
  `academy_module.dart`, `school.dart`, `academy_icon_registry.dart`.
- The old Academy-heavy `home_screen.dart` (replaced by `overview_screen.dart`
  in Stage 5), `academy_intro_screen.dart`/`gamification_intro_screen.dart`
  (onboarding screens the wizard no longer routes through),
  `missions_section.dart`/`mission_card_widget.dart` (removed from
  `PortfolioScreen` in Stage 5), and the old Home screen's own dashboard
  widgets (`next_action_card.dart`, `next_action_resolver.dart`,
  `knowledge_map_strip.dart`, `learning_hero_card.dart`,
  `portfolio_bridge_card.dart`) plus their sole remaining dependent,
  `core/widgets/module_chip.dart`.
- **Explicitly kept** (confirmed still live despite Academy-adjacent
  naming): `mission_status.dart`, `missions_remote_datasource.dart`,
  `missions_repository.dart`, `mission_display_catalog.dart` — all
  genuinely used by `PortfolioController` for its own mission-XP event
  bus, independent of the removed `MissionsSection` UI;
  `academy_bridge_cta.dart`, `portfolio_not_connected_card.dart`,
  `portfolio_reminder_banner.dart` — live on `overview_screen.dart`;
  `mission_reward_card.dart` — live on `journey_ready_screen.dart`. The
  outcome-based badges (`positive_return`, `portfolio_10k`, `portfolio_50k`,
  `dividend_hunter`) are unchanged, still tracked as debt per Decision 1.

`DI` lost its now-fully-unused `academyRemoteDataSource`/`labRemoteDataSource`
fields; `integration_test/app_test.dart` lost its Academy-tab drill-down
assertions and its `LessonScreen`-based module-completion test (both
exercised now-deleted screens) while keeping its still-valid
`AcademyCatalogRepository` cache-staleness test (that repository is one of
the 9 kept-live files).

One recovery during this pass: an initial bulk deletion of
`test/features/academy/` also caught `academy_test_fixtures.dart` and the 9
test files for the kept-live files above, despite them not being dead —
restored from git history before committing, since `flutter analyze`
caught the break immediately.

Full suite: 1303 unit/widget tests + 4 Linux integration tests, all green.
`flutter analyze`: no issues. `flutter build linux --debug`: succeeds.

Not done in this pass (tracked as debt, deferred until it becomes load-bearing):
the outcome-based badges migration.

## Update, 2026-09-04 (ecosystem integration contract)

Docs-only, branch `docs/ecosystem-integration`. The ecosystem is three
products now — Petrimonium Health shipped with its own `app_context`, its own
schema and its own Flutter app — and no document here said so. The integration
contract was pulled into a single canonical file in the backend
([`INTEGRATION.md`](../../Petrimonium-Backend/docs/INTEGRATION.md)); this repo
and the other two now point at it instead of restating contracts locally.
`docs/ARCHITECTURE/README.md` updated to match.

One piece of drift in this very file was found while verifying: the Stage 5
note below describes an `AcademyBridgeCta` rendering on `OverviewScreen`. That
file no longer exists anywhere in `lib/` — no cross-app bridge widget survives
in this repo. Left in place as history (that section records what Stage 5 did),
flagged here because it is exactly the failure mode the single-contract move is
meant to stop.
