# Petrimonium mobile ecosystem

## Topology

```text
Academy (simulated education) ─┐
Wallet  (real patrimony)      ─┼──> Petrimonium Backend
Health  (real cash flow)      ─┘

apps/* ──> packages/*    # source reuse only; apps remain separate products
```

The apps do not call each other and do not share an on-device database. There
is currently no operational OS-level deep-link bridge between products. All
data integration goes through the backend with the session's fixed
`app_context`.

## What is shared as a product concept

- one Petrimonium account;
- one Pet identity;
- one backend XP/level ledger;
- one Mentor service with an isolated context-specific branch per product.

These are backend contracts. A concept being shared does not mean its Flutter
screen is already in `packages/` or that every app uses the same client
implementation.

## What remains isolated

| Context | Owner | Must not cross into |
| --- | --- | --- |
| Health cash flow | Health | Wallet patrimony or Academy simulation |
| Wallet real investments | Wallet | Health account balance or Academy simulation |
| Academy curriculum/progress/simulation | Academy | Real financial contexts |
| Product navigation, copy and release identity | Each app | Shared packages as hardcoded product knowledge |

The backend is the enforcement point. Its
[`docs/INTEGRATION.md`](../../Petrimonium-Backend/docs/INTEGRATION.md) owns the
JWT/route/access matrix. This document owns only the mobile view and should not
duplicate that matrix.

## Current mobile sharing

Academy and Wallet consume `petrimonium_ui`,
`petrimonium_flutter_core` and `petrimonium_shared_features`. Health remains
self-contained while its genuinely common seams are evaluated. Auth, settings,
Pet and Mentor contain extraction candidates, but product-local state,
localization and behavior still differ.

The target is not maximum deduplication. The target is one maintained
implementation for behavior all products should receive together, configured
by each product where they differ.

## Cross-product experience

Future bridges may take a person from one product to another, but they carry a
concept or destination — never a financial value, account identifier, holding
or trusted authorization. The destination re-fetches allowed data with its own
context token and handles the other app not being installed.

## Change ownership

- New shared route, claim or isolation rule: backend contract first.
- New shared Flutter primitive: compare all apps, then follow
  [`MOBILE_ARCHITECTURE.md`](MOBILE_ARCHITECTURE.md).
- New product behavior or section: keep it in the owning app unless the
  three-product decision rule is satisfied.
- New Mentor/Pet presentation seam: follow
  [`PET_AND_MENTOR.md`](PET_AND_MENTOR.md).
