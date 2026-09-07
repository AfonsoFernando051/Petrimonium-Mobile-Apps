# Architecture documentation pointer

The old `Invest-Game-V2/docs/ARCHITECTURE.md` described a combined Flutter and
Spring Boot repository. That architecture is no longer current.

- Mobile monorepo, packages and dependency rules:
  [`MOBILE_ARCHITECTURE.md`](MOBILE_ARCHITECTURE.md)
- Product and ecosystem boundaries: [`ECOSYSTEM.md`](ECOSYSTEM.md)
- Backend Clean Architecture and end-to-end slices:
  [`Petrimonium-Backend/docs/ARCHITECTURE/`](../../Petrimonium-Backend/docs/ARCHITECTURE/)

This compatibility pointer exists because current source comments still refer
to `docs/ARCHITECTURE.md`. Add new architecture content to its owning document,
not here.
