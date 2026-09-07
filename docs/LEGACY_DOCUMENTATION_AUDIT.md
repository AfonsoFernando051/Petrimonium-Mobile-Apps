# Legacy documentation audit

**Audit date:** 2026-09-07

## Scope

Reviewed sources:

- `/home/fernando/eclipse-workspace/Invest-Game-V2/docs/`;
- `Legacy/Petrimonium-Academy/docs/`;
- `Legacy/Petrimonium-Wallet/docs/`;
- `Legacy/Petrimonium-Health/docs/`;
- the current `petrimonium-mobile` code and documents;
- current integration/content implementation in the sibling
  `Petrimonium-Backend` repository.

Legacy repositories were read-only evidence. Changes from this audit belong in
`petrimonium-mobile`.

## What was retained and updated

| Source material | Current destination | What was preserved |
| --- | --- | --- |
| `PRODUCT_VISION.md`, `PROJECT_CONTEXT.md` | `PRODUCT_VISION.md`, `PROJECT_CONTEXT.md` | Learning-first Academy, safety boundaries, Pet identity and historical origin, reframed for three products |
| `AGENTS.md`, `AI_RULES.md` | root `AGENTS.md`, `CODING_GUIDELINES.md` | Inspect-first workflow, incremental change, production quality, documentation discipline and product guardrails |
| `DESIGN_SYSTEM.md` | `DESIGN_SYSTEM.md` | Hierarchy, calm financial UX, tokens, accessible states and product visual distinction, mapped to `petrimonium_ui` |
| historical ADRs | `DECISIONS.md` | Only durable decisions that still constrain the mobile ecosystem |
| `AI_MENTOR.md`, speech-bubble design | `PET_AND_MENTOR.md` | Mentor safety, context separation, source disclosure and native Flutter dialogue presentation |
| `RIVE_PET_COMPANION_BRIEF.md` | `RIVE_PET_COMPANION_BRIEF.md` | Runtime/input/asset contract, corrected so financial events never drive celebration and Rive stays replaceable |
| `ACADEMY_ENGINE.md`, `ACADEMY_CONTENT_AUTHORING.md` | `apps/academy/docs/` | Current client responsibilities and backend-authored curriculum workflow |
| `.agents/.claude academy-content` skill | `.agents/skills/academy-content` | Curriculum authoring workflow with current monorepo/backend paths and dynamic validation |
| three legacy `ECOSYSTEM.md` files | root and app-specific docs | Product roles and obligations without duplicating the backend's canonical integration contract |

## What was not copied wholesale

| Historical document | Reason |
| --- | --- |
| `ARCHITECTURE.md` | Describes the old combined Flutter/backend repository; superseded by `MOBILE_ARCHITECTURE.md` and backend architecture docs |
| `API_GUIDELINES.md` | Mostly backend REST policy; backend owns it. Health's current client-facing API contract remains under `apps/health/docs/API.md` |
| `FEATURES.md` | Mixes Academy and real portfolio into one product. Durable product rules moved to `PRODUCT_VISION.md`; current behavior stays with each app |
| `MARKET_EVENTS_ENGINE.md` | Largely an aspirational combined-app design. The still-valid no-financial-reward/Pet rules were retained; speculative architecture was not |
| `ROADMAP.md` | Alpha/Beta/V1 plan predates the three-product split and is not a reliable current commitment |
| `IDEA_ACADEMY_CONTENT_ADMIN.md` | Deferred backend/tooling idea, not a current mobile requirement |

Nothing is lost: the original files remain in Git/history and the historical
repositories. They are intentionally not current sources of truth.

## Drift found during the audit

- App README and docs linked to the backend using paths from the former
  separate-repository layout; the links were corrected for `apps/*` inside the
  monorepo.
- The imported `ECOSYSTEM.md` files were identical to their legacy copies and
  contained chronological migration logs, now-invalid repo claims and dead
  paths. They were replaced with current product-local summaries.
- Root architecture implied all three apps consume the shared packages. Current
  manifests show Academy and Wallet do; Health remains self-contained. The
  architecture now labels this explicitly as Current versus Target.
- Legacy Health docs reported `/api/mentor/**` as a permanent 403. Current
  backend code includes a Health-specific prompt branch and grants
  `APP_CONTEXT_HEALTH`; mobile docs now describe it as supported.
- The backend's `docs/INTEGRATION.md` still contains the earlier Health Mentor
  gap in its known-gaps section even though current code has resolved it. That
  canonical backend document should be corrected in a backend-scoped change;
  it was not edited from this mobile-only audit.
- Academy curriculum counts in historical docs/skills had drifted. The current
  backend contains 8 domains, 19 schools, 57 modules, 361 lessons and 1,815
  steps at audit time. New guidance computes counts dynamically rather than
  treating these numbers as permanent.

## Maintenance rule

Do not append session-by-session implementation diaries to architecture or
ecosystem documents. Keep them focused on current stable facts and target
statements that are clearly labelled. Git history is the chronological record;
`DECISIONS.md` records durable trade-offs.
