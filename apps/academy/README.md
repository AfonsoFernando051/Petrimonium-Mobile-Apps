# Petrimonium Academy

Financial education and simulated practice: *do I understand what I am
doing?* Academy is one independently released application inside the
Petrimonium mobile monorepo.

## Read first

| Document | Purpose |
| --- | --- |
| [`../../docs/PRODUCT_VISION.md`](../../docs/PRODUCT_VISION.md) | Ecosystem and Academy learning/safety principles |
| [`../../docs/MOBILE_ARCHITECTURE.md`](../../docs/MOBILE_ARCHITECTURE.md) | Monorepo and shared-package rules |
| [`docs/ECOSYSTEM.md`](docs/ECOSYSTEM.md) | Academy's current role and boundaries |
| [`docs/ACADEMY_ENGINE.md`](docs/ACADEMY_ENGINE.md) | Current Academy mobile responsibilities |
| [`docs/ACADEMY_CONTENT_AUTHORING.md`](docs/ACADEMY_CONTENT_AUTHORING.md) | How curriculum is authored in the backend |
| [`../../../Petrimonium-Backend/docs/INTEGRATION.md`](../../../Petrimonium-Backend/docs/INTEGRATION.md) | Canonical integration and data-isolation contract |

## Run

From the monorepo root:

```bash
melos bootstrap
cd apps/academy
flutter run --dart-define=API_BASE_URL=http://localhost:8081
```

For an Android emulator, use `http://10.0.2.2:8081`. `API_BASE_URL` must be
provided for profile/release builds; the app refuses to start a release that
would point to localhost.

Useful checks:

```bash
flutter analyze
flutter test
```

Use `melos run verify` from the root when a shared package changes.

## Product and release identity

- Dart package: `petrimonium_academy`
- Android/bundle identifier: `com.petrimonium.academy`
- Backend context: `academy` (fixed, not a build flavor)
- Money shown in Academy practice: simulated only

OAuth native clients, store records, signing and versions remain independent
from Wallet and Health. Supply backend URL, Sentry DSN and signing secrets at
build/release time; never commit real credentials or `android/key.properties`.

## Architecture notes

Academy consumes `petrimonium_ui`, `petrimonium_flutter_core` and
`petrimonium_shared_features`, while keeping product navigation, copy, content
presentation and Academy behavior local. Curriculum content and authoritative
progress/XP live in the backend; content-only edits do not require a mobile
release.
