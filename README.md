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

The Spring Boot backend is **not** in this repository. It lives in
`Petrimonium-Backend` and remains the authoritative owner of the ecosystem's
domain rules.

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
