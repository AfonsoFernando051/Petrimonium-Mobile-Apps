# Petrimonium Wallet

Real investment patrimony organization and interpretation: *how is my
patrimony, and what is it doing?* Wallet is one independently released
application inside the Petrimonium mobile monorepo.

## Read first

| Document | Purpose |
| --- | --- |
| [`../../docs/PRODUCT_VISION.md`](../../docs/PRODUCT_VISION.md) | Ecosystem and financial-safety principles |
| [`../../docs/MOBILE_ARCHITECTURE.md`](../../docs/MOBILE_ARCHITECTURE.md) | Monorepo and shared-package rules |
| [`docs/ECOSYSTEM.md`](docs/ECOSYSTEM.md) | Wallet's current role and boundaries |
| [`../../../Petrimonium-Backend/docs/INTEGRATION.md`](../../../Petrimonium-Backend/docs/INTEGRATION.md) | Canonical integration and data-isolation contract |

## Run

From the monorepo root:

```bash
melos bootstrap
cd apps/wallet
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

- Dart package: `petrimonium_wallet`
- Android/bundle identifier: `com.petrimonium.wallet`
- Backend context: `wallet` (fixed, not a build flavor)
- Financial context: real investments/patrimony, without order execution

OAuth native clients, store records, signing and versions remain independent
from Academy and Health. Supply backend URL, Sentry DSN and signing secrets at
build/release time; never commit real credentials or `android/key.properties`.

## Architecture notes

Wallet consumes `petrimonium_ui`, `petrimonium_flutter_core` and
`petrimonium_shared_features`, while keeping product navigation, copy,
portfolio behavior and market presentation local. Wallet must not treat Health
cash flow as investable balance, expose Academy simulations as real data or
reward a financial result.
