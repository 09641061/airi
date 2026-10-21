# Application Command/Query Services & ACL — Prove Orchestration Without Mock Theater

**Production locations:**

- `[context-name]/application/commandservices/`
- `[context-name]/application/queryservices/`
- `[context-name]/application/acl/`
- `[context-name]/application/outboundservices/acl/` (if used)

The application layer coordinates domain behavior. It does **not** replace aggregate invariant tests. The command service's dependencies are domain repository interfaces from `domain/repositories/`, not concrete PostgreSQL repositories.

## A. Command Service tests

Test business-level orchestration:

- A **real aggregate** is loaded from a deterministic fake domain repository.
- Application passes the **actual command** to the aggregate's business method, and resulting state is persisted when valid.
- Domain rejection is propagated or translated correctly; state is not persisted and no outbox integration message is recorded.
- Repository not-found, version conflict, cancellation, or transient failure are handled according to the service contract.
- If an operation spans multiple repositories, the transaction abstraction is invoked correctly, but **real rollback guarantees are only proven against the DB**.
- Duplicate or replayed commands do not create duplicated external effects where idempotency is required.
- Domain events are translated to integration messages where needed; outbox persistence accompanies business changes in the same actual transaction (integration test).
- No implementation-detail call-count assertions unless ordering/frequency is itself a **business guarantee**.

### Preferred fake (template)

A fake must behave sufficiently like the **domain repository contract** for the scenario. It is not a replacement for the real PostgreSQL adapter.

```go
// Replace Aggregate, AggregateID and Clone with the actual domain contract.
// Clone is illustrative; if the domain has no copy API, build a contract-faithful
// fake that avoids unintended pointer aliasing by another supported mechanism.
type fakeAggregateRepository struct {
    byID    map[domain.AggregateID]*domain.Aggregate
    saveErr error
}

func (r *fakeAggregateRepository) FindByID(
    ctx context.Context, id domain.AggregateID,
) (*domain.Aggregate, error) {
    if err := ctx.Err(); err != nil { return nil, err }
    aggregate, ok := r.byID[id]
    if !ok { return nil, domain.ErrNotFound }
    return aggregate.Clone(), nil
}

func (r *fakeAggregateRepository) Save(
    ctx context.Context, aggregate *domain.Aggregate,
) error {
    if err := ctx.Err(); err != nil { return err }
    if r.saveErr != nil { return r.saveErr }
    r.byID[aggregate.ID()] = aggregate.Clone()
    return nil
}
```

**Important:** the above is a contract template, not executable against an unspecified domain. A fake that shares the aggregate pointer across calls may hide missing `Save` operations; isolation or snapshots should reflect real persistence behavior.

### Strong command-service assertion

In a successful command test, read the resulting aggregate from the fake repository and verify its **business state**, identity, and expected application result. In a rejected command test, inspect the persisted snapshot (not only returned `error`) and ensure there was no committed change. If an outbound message was required, verify its meaningful payload using a narrow recorder.

## B. Query Service tests

- Query returns the correct projection, ordering, and pagination metadata from controlled repository/read-port results.
- Invalid query/unsupported ordering returns the documented error rather than silently broadening the search.
- No writes or outbound side effects.
- Context cancellation and read-port failures propagate correctly.
- Large result sets are constrained by page/cursor contracts.
- Actual SQL ordering and pagination edge cases belong in repository **integration tests**.

## C. ACL — integration across bounded contexts

The provider exposes an ACL facade. The consumer translates provider concepts into its own local model. Do not import provider aggregates or simulate both contexts using the same domain object.

Critical cases:

1. Successful translation of IDs and domain terms; no accidental semantic mismatch.
2. Provider returns not found — consumer distinguishes it from transport/system failure.
3. Provider returns business rejection — translate to consumer-understandable error.
4. Provider unavailable/timeout/cancellation — do not incorrectly create success state.
5. Duplicate/parallel requests — uphold the actual idempotency contract.
6. Failure after lookup but before mutation — no inconsistent consumer state.
7. Facade contract compatibility — tests guard exported shapes/semantics, not internal struct arrangement.
8. No circular imports or direct provider repository access.

**Doubles:** use a stub of the **provider ACL facade boundary**, not a fake provider aggregate. When both contexts live in the same monolith, add a focused component test wiring the actual provider facade to its application service and verify translation with controlled persistence.

## D. Transaction policy

Unit tests can prove that a required transaction abstraction is used and a failure prevents further application work. Only PostgreSQL integration tests prove:

- a failed write rolls back earlier writes;
- outbox events are atomic with aggregate changes;
- isolation level, locking, unique constraints, and optimistic concurrency behave as intended.

Avoid translating `@Transactional` Java tests literally into Go. A Go transaction is explicit and does not exist because of an annotation.

## Anti-patterns

- Mock returns a pre-built response → test asserts that same response → **no business logic tested**.
- `EXPECT().Save(...)` without checking the resulting domain state when that is the contract.
- Mocking aggregate methods like `Transition()` and then asserting they were called.
- A fake repository that does not model documented not-found, duplicate, or version semantics when relevant.
- Verifying exact call order of reads when order is not observable or contractual.

## Checklist

- [ ] Uses real domain objects and a contract-faithful repository fake where suitable.
- [ ] Proves persisted business state, not just method invocation.
- [ ] Proves failure state remains unchanged.
- [ ] Distinct typed errors and cancellation are tested.
- [ ] ACL semantic translation and error mapping are covered.
- [ ] True ACID behavior has a separate integration test.
