# Application Layer — One Use Case at a Time

Source: guide §§3–4, 8, 16. Location: `internal/[context-name]/application/` or a cohesive feature package. Application coordinates domain behavior and consumed capabilities; it does not import Gin, transport DTOs, concrete adapters, or engine transaction handles.

## Define the use-case contract

Record intent, input, result, owning context, authorization/preconditions, errors, and required consistency. A plain Go input struct is sufficient. Keep the command/query, result, narrow port, and handler together in a file such as `confirm_enrollment.go` when they form one responsibility.

Do not impose commands/results/commandservices/queryservices packages. Preserve useful existing divisions. Introduce `application/confirmation/` only when feature cohesion and a meaningful API justify a package, not to reduce line count. A parent facade and its feature packages must not import each other cyclically.

Inbound use-case interfaces are useful as consumed boundaries or published module APIs. A concrete handler is enough for a single internal implementation without a real abstraction need. Do not add a pass-through facade merely because a layer diagram contains one.

## Implement a command

1. Accept request context explicitly, normally first, and propagate it to downstream I/O.
2. Check use-case preconditions: authorization, required records, idempotency, and workflow readiness. A conditional here is not automatically domain leakage.
3. Load the aggregate through the narrow consumer-owned port, or use the transaction-bound capabilities supplied by a justified provider.
4. Invoke domain methods; do not duplicate their invariants in orchestration.
5. Persist according to the declared concurrency/atomicity contract.
6. Return the required identifier/result only when the operation's completion guarantee is satisfied. Transaction-local results remain provisional until commit.
7. Coordinate external effects according to explicit failure/retry semantics, never as unsafe work inside a retryable storage callback.

Application decides **what must agree atomically**; infrastructure decides how the engine provides it. Do not hide transaction handles in context or assume unrelated repositories are bound together. See [persistence](persistence.md).

A simple CRUD command may use a focused store port without a rich aggregate. Do not invent entities, events, or invariants just to make every operation follow the same route.

## Implement a query

- Express a focused information request and explicit result/absence contract.
- Return a projection owned by application when no domain behavior is required; do not rebuild an aggregate merely to serialize a list.
- Validate filtering/sorting/pagination and enforce bounded sizes and deterministic order.
- Do not mutate business state as a read side effect.
- Use a consumed read port rather than concrete queries, ORM types, or sqlc-generated interfaces in application.

CQS separates intentions conceptually. Separate read models/stores, deployment, decorators, or a bus require actual complexity/load benefits; no automatic CQRS scaffold.

## Ownership and integration

Publish only the intentionally supported application contract. A consumer uses its own capability port and adapts the provider outside the consuming core. Do not return foreign private aggregates or share repositories because both contexts use one database. See [context integration](context-integration.md).

Error categories belong to the package owning their meaning; wrap with `%w` when preserving a cause is part of the contract. Neither application nor domain selects HTTP statuses. See [errors](errors.md).

## Verification

Use real domain objects with small contract-faithful fakes/stubs at external boundaries. Assert business-visible results, stored state, rejection without forbidden effects, and required coordination. A fake cannot prove SQL isolation, rollback, or actual commit behavior; verify those in `/test/integration`.

Before delivery, verify consumer-owned interfaces, propagation of cancellation, bounded reads, explicit command consistency, and composition-root wiring. Preserve published routes/payloads/statuses and schema during architectural moves; separate approved behavior changes.
