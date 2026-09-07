# Wallet architecture pointer

Read the monorepo architecture first:
[`docs/MOBILE_ARCHITECTURE.md`](../../../../docs/MOBILE_ARCHITECTURE.md).

End-to-end backend slices and the canonical integration contract live in the
sibling backend:

- [`Petrimonium-Backend/docs/ARCHITECTURE/`](../../../../../Petrimonium-Backend/docs/ARCHITECTURE/)
- [`Petrimonium-Backend/docs/INTEGRATION.md`](../../../../../Petrimonium-Backend/docs/INTEGRATION.md)

Current client facts: `app_context = wallet`; static DI composition root;
shared `ApiClient`; real patrimony only; no order execution.

Academy and Wallet share ancestry, but same-path files may have diverged.
Compare implementations before moving a fix into a package.
