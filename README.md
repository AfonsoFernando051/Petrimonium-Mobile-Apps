# Petrimonium Mobile

The three Petrimonium Flutter products and the packages they share.

| App | Purpose |
| --- | --- |
| [`apps/academy`](apps/academy) | Financial education and learning habits |
| [`apps/wallet`](apps/wallet) | Portfolio organization, monitoring and analysis |
| [`apps/health`](apps/health) | Financial health diagnosis, goals and periodic evolution |

They share an identity, a Pet/Mentor and a backend, but they are separate
products with separate release cycles. A Wallet release does not require
building or publishing Academy or Health.

The Spring Boot backend is **not** in this repository. It lives in the sibling
[`Petrimonium-Backend`](../Petrimonium-Backend) repository and remains the
authoritative owner of the ecosystem's domain and integration rules.

## Documentation

Start with [`AGENTS.md`](AGENTS.md), even when working manually: it is the
compact map of product boundaries and the reading order. The durable sources
of truth are:

| Document | Question |
| --- | --- |
| [`docs/PRODUCT_VISION.md`](docs/PRODUCT_VISION.md) | What are the three products and what must they never become? |
| [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md) | How did this monorepo arise and which repository owns each kind of truth? |
| [`docs/ECOSYSTEM.md`](docs/ECOSYSTEM.md) | What connects the products and what remains isolated? |
| [`docs/MOBILE_ARCHITECTURE.md`](docs/MOBILE_ARCHITECTURE.md) | What may be shared and how do dependencies flow? |
| [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) | What is visually shared versus product-configured? |
| [`docs/CODING_GUIDELINES.md`](docs/CODING_GUIDELINES.md) | How should Flutter changes be structured and verified? |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Which durable trade-offs are already accepted? |
| [`docs/PET_AND_MENTOR.md`](docs/PET_AND_MENTOR.md) | How are Mentor intelligence, Pet identity and presentation separated? |

## Getting started

```bash
dart pub global activate melos 6.3.2
melos bootstrap
melos run verify          # analyze + test everything
```

Run one product:

```bash
cd apps/academy && flutter run
```

**Read [`docs/MOBILE_ARCHITECTURE.md`](docs/MOBILE_ARCHITECTURE.md) before
adding anything to `packages/`.** It carries the rule that decides whether
code is shared, what belongs in each package, and what is deliberately still
duplicated and why.
