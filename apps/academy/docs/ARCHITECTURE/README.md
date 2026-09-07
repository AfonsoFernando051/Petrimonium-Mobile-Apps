# Academy architecture pointer

Read the monorepo architecture first:
[`docs/MOBILE_ARCHITECTURE.md`](../../../../docs/MOBILE_ARCHITECTURE.md).

Academy-specific client architecture is documented in
[`../ACADEMY_ENGINE.md`](../ACADEMY_ENGINE.md). End-to-end backend slices and
the canonical integration contract live in the sibling backend:

- [`Petrimonium-Backend/docs/ARCHITECTURE/`](../../../../../Petrimonium-Backend/docs/ARCHITECTURE/)
- [`Petrimonium-Backend/docs/INTEGRATION.md`](../../../../../Petrimonium-Backend/docs/INTEGRATION.md)

Current client facts: `app_context = academy`; static DI composition root;
shared `ApiClient`; backend-authored curriculum; simulated money only.
