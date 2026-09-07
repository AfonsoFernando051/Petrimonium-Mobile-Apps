# Cross-repository contracts — historical pointer

The original Academy document proposed `app_context`, Pet state and deep-link
contracts before the other products and backend had agreed on them. It is no
longer a contract and must not be used to implement current behavior.

Current authorities:

- backend integration, JWT contexts, route access and data isolation:
  [`Petrimonium-Backend/docs/INTEGRATION.md`](../../../../Petrimonium-Backend/docs/INTEGRATION.md);
- mobile dependency/composition rules:
  [`../../../docs/MOBILE_ARCHITECTURE.md`](../../../docs/MOBILE_ARCHITECTURE.md);
- Pet/Mentor client presentation:
  [`../../../docs/PET_AND_MENTOR.md`](../../../docs/PET_AND_MENTOR.md).

The historical reasoning remains available in the legacy repository and Git
history. Keeping only this pointer prevents an obsolete proposal from looking
like a second source of truth.
