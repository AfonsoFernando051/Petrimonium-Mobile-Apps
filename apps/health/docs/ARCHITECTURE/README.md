# Health architecture pointer

Read the monorepo architecture first:
[`docs/MOBILE_ARCHITECTURE.md`](../../../../docs/MOBILE_ARCHITECTURE.md).

End-to-end backend slices and the canonical integration contract live in the
sibling backend:

- [`Petrimonium-Backend/docs/ARCHITECTURE/`](../../../../../Petrimonium-Backend/docs/ARCHITECTURE/)
- [`Petrimonium-Backend/docs/INTEGRATION.md`](../../../../../Petrimonium-Backend/docs/INTEGRATION.md)

Current client facts: `app_context = health`; `HealthController` +
`HealthScope`; local network layer; ARB localization; local Health theme; no
shared-package dependency yet.

Health does not descend from the Academy/Wallet clone. Do not copy their DI,
network or localization patterns into Health without a verified shared seam.
