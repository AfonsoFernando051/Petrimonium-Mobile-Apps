# Academy curriculum authoring

## Ownership

Curriculum is not authored in Flutter. The canonical source is the sibling
backend:

```text
Petrimonium-Backend/src/main/resources/academy-content/
├── domains.json
└── schools/{domainId}/{schoolId}.json
```

`AcademyContentSeedRunner` loads/upserts the JSON. The Academy app fetches the
catalog from `/api/v1/academy/catalog`; content-only changes do not require a
mobile release.

Use the repository skill `.agents/skills/academy-content` for an assisted
authoring task. The backend directory's own `README.md` and DTOs are the final
authority if the schema changes.

## Stable identity rules

- `domainId`, `schoolId`, `moduleId` and `lessonId` are permanent after
  release. Progress and XP reference them.
- Never rename/reuse an existing ID. To retire content, set
  `contentAvailable: false` instead of deleting it.
- IDs are lowercase English `snake_case` slugs.
- `order` is 1-based and sequential within the immediate parent.
- Check the entire content tree for a proposed ID before adding it.

## Localized content

Every authored level supplies complete `pt`, `en` and `es` translations.
Languages must carry the same meaning, numbers and answer correctness.

Content must:

- explain mechanisms, alternatives and trade-offs without buy/sell advice;
- use encouraging, non-punitive feedback;
- avoid guaranteed returns and price predictions;
- use plausible distractors with exactly one correct choice;
- state jurisdiction and verification for time-sensitive tax/legal claims when
  those claims are made.

## Current JSON shape

A school file owns its modules, lessons and steps:

```json
{
  "schoolId": "stable_school_id",
  "domainId": "existing_domain_id",
  "order": 1,
  "iconKey": "existing_icon_key",
  "contentAvailable": true,
  "prerequisites": [],
  "translations": {
    "pt": {"title": "...", "description": "..."},
    "en": {"title": "...", "description": "..."},
    "es": {"title": "...", "description": "..."}
  },
  "modules": []
}
```

New modules should include `difficulty` (`FOUNDATION`, `BEGINNER`,
`INTERMEDIATE`, `ADVANCED` or `SPECIALIZATION`), prerequisites and complete
translations. Existing content may predate metadata fields; do not bulk-rewrite
it during an unrelated addition.

New lessons should normally include:

- stable `lessonId`, 1-based `order` and existing XP convention;
- `competency` (`RECOGNIZE`, `EXPLAIN`, `CALCULATE`, `INTERPRET`, `COMPARE`,
  `APPLY`, `DECIDE` or `INTEGRATE`);
- `estimatedMinutes` based on actual steps;
- a checkable `learningObjective` for every language;
- optional `portfolioConcepts` only when it maps to a real supported indicator;
- taxation-only metadata (`jurisdiction`, `effectiveDate`, `lastVerifiedAt`,
  `source`) only when verified.

A compact lesson usually follows:

```text
explanation -> example -> choice_question (recall)
            -> choice_question (apply) -> summary
```

Step translation fields depend on type:

- `explanation`/`example`: `title`, `body`;
- `choice_question`: top-level `framing` and zero-based `correctIndex`, plus
  localized `prompt`, `options`, `explanation`;
- `summary`: localized `title`, `takeaways`.

Read a comparable current school JSON and the backend seed DTOs before
authoring. Do not rely on copied counts or a remembered schema.

## Workflow

1. Locate the sibling backend and verify it is the intended repository/branch.
2. Read `academy-content/README.md`, the target school JSON and a comparable
   lesson in full.
3. Inventory current IDs, content availability and true entity counts.
4. Draft the smallest requested addition, preserving existing structure and
   voice.
5. Review all translations, `correctIndex`, safety language, prerequisites,
   metadata and IDs.
6. Validate every changed JSON file.
7. Recompute totals and update the exact assertions in
   `AcademyContentSeedRunnerTest`.
8. Run the focused backend seed test, including idempotency/progress
   preservation.
9. Do not change Flutter for a content-only request.

## Useful validation

From `Petrimonium-Backend/src/main/resources/academy-content`:

```bash
python3 -m json.tool schools/<domain>/<school>.json >/dev/null

python3 - <<'PY'
import glob, json

domains = json.load(open('domains.json'))['domains']
schools = modules = lessons = steps = 0
for path in glob.glob('schools/*/*.json'):
    school = json.load(open(path))
    schools += 1
    for module in school.get('modules', []):
        modules += 1
        for lesson in module.get('lessons', []):
            lessons += 1
            steps += len(lesson.get('steps', []))
print('domains', len(domains), 'schools', schools,
      'modules', modules, 'lessons', lessons, 'steps', steps)
PY
```

Then, from the backend root:

```bash
./mvnw -Dtest=AcademyContentSeedRunnerTest test
```

Counts are deliberately computed, not documented as permanent numbers. At the
2026-09-07 audit they matched the backend test at 8 domains, 19 schools, 57
modules, 361 lessons and 1,815 steps.

## Client contract checks

An `iconKey` unknown to
`apps/academy/lib/features/academy/domain/services/academy_icon_registry.dart`
falls back silently. Verify it against the current registry. Likewise, only
use `portfolioConcepts` accepted by the current Academy/Wallet interpretation
bridge; absence is better than a fabricated mapping.
