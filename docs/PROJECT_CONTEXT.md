# Petrimonium Mobile — project context

## What this repository is

`petrimonium-mobile` is the source-code monorepo for three independent Flutter
applications and the packages they deliberately share:

```text
apps/academy   apps/wallet   apps/health
        \          |          /
                  packages/*
```

The monorepo reduces accidental drift in truly common client code. It does not
combine product journeys, release cycles, native identifiers, assets or
business rules.

The Spring Boot backend is a sibling repository,
[`../../Petrimonium-Backend`](../../Petrimonium-Backend), and remains a
separate system with Clean Architecture. Backend business logic must not be
moved into Flutter.

## Where the code came from

- `Invest-Game-V2` was the older combined prototype/product line. Its
  learning-first vision, safety constraints, Academy curriculum practice and
  Pet/Mentor design work remain useful historical input.
- `Legacy/Petrimonium-Academy` and `Legacy/Petrimonium-Wallet` were split from
  that lineage. They share substantial code because of ancestry, not because
  every identical file is a valid abstraction.
- `Legacy/Petrimonium-Health` was developed separately. Its state, network,
  localization and visual patterns differ for real reasons.
- The three app histories were imported under `apps/`; shared client code was
  then extracted incrementally into `packages/`.

The legacy repositories and `Invest-Game-V2` are now references, not current
specifications. Do not copy their paths, statuses or combined-app assumptions
into new work without checking this monorepo and the backend.

## Documentation ownership

| Question | Canonical owner |
| --- | --- |
| What the products are and what they must never become | [`PRODUCT_VISION.md`](PRODUCT_VISION.md) |
| Mobile dependency and sharing rules | [`MOBILE_ARCHITECTURE.md`](MOBILE_ARCHITECTURE.md) |
| Shared visual language | [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) |
| Accepted mobile/product decisions | [`DECISIONS.md`](DECISIONS.md) |
| JWT context, endpoint access and cross-product data isolation | [`Petrimonium-Backend/docs/INTEGRATION.md`](../../Petrimonium-Backend/docs/INTEGRATION.md) |
| Backend implementation and domain rules | `Petrimonium-Backend/docs/` and backend code |
| Product-specific client behavior | `apps/<product>/README.md`, `apps/<product>/docs/` and current code |

When documents disagree, prefer the owner in this table. Current code wins
over an unlabelled historical statement for what is actually shipped, but the
code does not override a product-safety boundary silently: record and resolve
the conflict.

## Current versus target

Documentation must say whether a statement describes **Current** behavior or
a **Target**. This matters during incremental migration:

- Academy and Wallet currently consume all three shared packages.
- Health currently remains self-contained and has not adopted those packages.
- Auth, settings, Mentor and Pet presentation still contain known duplication.
  Similarity alone is not authorization to extract them.
- The target is composition/configuration-based reuse where all three products
  genuinely benefit, without forcing localization or behavior convergence.

Do not describe a planned package edge, deep link or shared screen as shipped.

## Pet Companion

The Pet is the shared emotional identity, while its intelligence and visual
experience remain separate concerns. Pet state/progression is backend-owned;
Flutter supplies a renderer-neutral experience and product-specific copy. It
never represents wealth, market performance or risk tolerance. See
[`PET_AND_MENTOR.md`](PET_AND_MENTOR.md).

## Working philosophy

- Inspect first and migrate incrementally.
- Preserve each product's observable behavior during architectural work.
- Prefer a small explicit seam over a universal abstraction.
- Keep product copy in the product; shared widgets receive it as input.
- Keep backend rules in the backend; mobile models and validation exist to
  support user experience, not to become a second authority.
- Update documentation in the same change when an architectural fact changes.

The documentation migration that established these sources of truth is
recorded in [`LEGACY_DOCUMENTATION_AUDIT.md`](LEGACY_DOCUMENTATION_AUDIT.md).
