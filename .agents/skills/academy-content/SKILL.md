---
name: academy-content
description: Add or expand Petrimonium Academy curriculum content in the sibling backend's JSON seed catalog. Use for new or revised domains, schools, modules, lessons or lesson steps; do not use for ordinary Flutter UI changes.
---

# Academy content authoring

Author curriculum in `Petrimonium-Backend`, never in Flutter. The mobile repo
contains the client and the maintained authoring guide, while the sibling
backend owns the JSON, seed runner, stable IDs and tests.

## Orient before editing

1. Locate the mobile repository root and its sibling `Petrimonium-Backend`.
   Do not assume the current directory or the historical name
   `PetApp-Backend`.
2. Read `apps/academy/docs/ACADEMY_CONTENT_AUTHORING.md` in the mobile repo.
3. Read
   `Petrimonium-Backend/src/main/resources/academy-content/README.md`, the
   target school JSON and the current seed DTOs.
4. Confirm the backend repository/branch and preserve unrelated work. A
   curriculum request authorizes content changes in the backend; it does not
   authorize unrelated mobile or backend refactoring.

## Determine the real baseline

Compute current domain/school/module/lesson/step counts from the JSON and
compare them with `AcademyContentSeedRunnerTest`. Never trust counts copied
into prose. Inventory existing IDs and confirm where the requested content fits
before drafting it.

If the JSON and test are already inconsistent, report the pre-existing drift
before mixing it with the requested content delta.

## Authoring contract

- Preserve existing `domainId`, `schoolId`, `moduleId` and `lessonId` forever.
  Never rename/reuse them; retire content with `contentAvailable: false`.
- Use stable lowercase English `snake_case` for new IDs and search globally
  before accepting one.
- Keep `order` 1-based and sequential inside each parent.
- Supply complete equivalent `pt`, `en` and `es` content.
- Teach mechanisms and trade-offs. Never provide personalized buy/sell advice,
  deterministic allocations, guarantees or price predictions.
- Wrong-answer explanations are neutral and useful, never punitive.
- Choice questions have one correct option and a verified zero-based
  `correctIndex`.
- For new content, include current learning metadata where applicable:
  module `difficulty`; lesson `competency`, `estimatedMinutes` and translated
  `learningObjective`.
- Use `portfolioConcepts` only for an existing client-supported indicator.
- Use jurisdiction/effective/verification/source metadata only for genuinely
  verified time-sensitive tax or legal claims.
- Use only an `iconKey` supported by the current Academy icon registry.

Read a comparable current JSON object instead of reconstructing the schema
from memory. Existing older lessons may omit newer optional metadata; do not
bulk-rewrite them during an unrelated addition.

## Preferred lesson shape

A concise lesson normally contains explanation, example, recall question,
application question and summary. Vary the shape when the learning objective
requires it; do not add filler to hit a fixed count.

The highest declared competency must be exercised by the steps. A calculation
lesson must actually calculate; a comparison/decision lesson must make the
learner weigh meaningful alternatives.

## Validate

1. Validate each changed JSON file with `python3 -m json.tool`.
2. Re-read the exact inserted object and verify all language branches,
   `correctIndex`, IDs, prerequisites and availability flags.
3. Recompute whole-catalog counts.
4. Update exact count assertions in `AcademyContentSeedRunnerTest`.
5. Run `./mvnw -Dtest=AcademyContentSeedRunnerTest test` from the backend root.
   The count, idempotency and existing-progress-preservation cases must pass.
6. Do not edit or release Flutter for content-only changes.

If current backend DTOs or the backend content README conflict with the mobile
guide, the current backend wins. Update the mobile guide in the same task when
the discrepancy represents a durable schema/workflow change.
