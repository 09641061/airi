# Testing and delivery

Four test layers, each with a distinct scope and tooling. Run all of them; do not collapse them.

## 1. Domain tests

- **Scope:** value-object validation, invariants, state transitions.
- **No Gin, no database, no mocks.** Pure functions over `*Order`.
- **Tools:** `testing` standard library; table-driven tests; testify/require is fine if you already use it.
- Examples worth covering:
  - `ParseID` / `ParseTenantID` / `NewSKU` reject bad inputs.
  - `Order.AddLine` returns `ErrOrderNotDraft` on a Submitted order.
  - `Order.Submit` returns `ErrEmptyOrder` on a draft with zero lines.
  - `ReconstituteOrder` rejects an invalid persisted state (bad status, Submitted with no lines).

## 2. Application tests

- **Scope:** orchestration: create, add, submit, error propagation.
- **Use hand-rolled fakes**, not a mocking framework. The repository port has three methods; a fake is ten lines.
- **What to verify:**
  - `CreateOrder` returns the repository's stored ID, wraps persistence errors.
  - `AddLine` and `SubmitOrder` reload, mutate, save with the right `expectedVersion`.
  - Domain errors from `Order.AddLine` / `Order.Submit` propagate untouched (no wrapping) so the adapter can classify them with `errors.Is`.
  - Wrapped infrastructure errors preserve `%w` so callers can still classify.

## 3. Repository integration tests

- **Scope:** the persistence adapter against a real (or ephemeral) database.
- **Tools:** testcontainers (Postgres / Mongo / LocalStack), or a Docker compose file in CI.
- **Cover at minimum:**
  - Round-trip: write a domain-constructed aggregate → read → `ReconstituteOrder` matches the original.
  - Stale-write rejection: read, mutate, save with an outdated version → `ErrConcurrentModification`.
  - Tenant isolation: a query for tenant A never returns rows owned by tenant B.
  - Constraints: duplicate keys, FK violations, invalid status transitions on data.
  - Transaction rollback: a partial failure inside the adapter rolls back the whole write.

## 4. HTTP / contract tests

- **Scope:** the Gin adapter end-to-end.
- **Tools:** `httptest.NewRecorder` + `gin.CreateTestContext`, or a small in-process `httptest.Server`.
- **Cover:**
  - Validation: bad `id`, bad `sku`, bad `quantity` → `400` with the right body.
  - Missing / wrong tenant → `401`.
  - Successful submit → `204`.
  - Stable error mapping: every domain error in `writeOrderError` has an assertion.
  - Tenant from middleware, never from header/body: a request that sets `X-Tenant-Id` directly is ignored.
  - OpenAPI 3.1 conformance: the spec file is generated or hand-written and committed; smoke-test a representative endpoint against it.

## Pre-release checklist

Before shipping a new bounded context (or a breaking change), verify:

- [ ] **Cancellation / timeouts** — every use case respects `ctx.Done()`; no goroutine outlives the request.
- [ ] **Authorization** — every endpoint has tenant middleware before the handler; tenant is never read from request data.
- [ ] **Sensitive-data-safe logs** — no request bodies, no tokens, no PII in logs; structured logging (`log/slog`) with redaction.
- [ ] **Migrations** — schema changes have an up and a down migration; the migration is applied in the same release as the code that needs it.
- [ ] **Graceful shutdown** — the HTTP server, the DB pool, and any background workers drain on SIGTERM; no half-written aggregates on the floor.
- [ ] **Health and readiness** — `/healthz` (process up) and `/readyz` (DB reachable) wired into the orchestrator.
- [ ] **Observability** — request IDs, structured logs, key spans over use-case boundaries.
- [ ] **OpenAPI 3.1** — spec committed, served at `/docs` or equivalent, kept in lock-step with the handlers.