# Domain Events, Aggregates, Entities, Domain Services & Repository Policy

This is the **highest-priority section**. A critical business aggregate needs more than a happy-path constructor test; it needs executable specifications for the constraints that keep the business consistent.

**Production locations:**

- `[context-name]/domain/model/entities/`
- `[context-name]/domain/model/aggregates/`
- `[context-name]/domain/model/events/`
- `[context-name]/domain/services/`
- `[context-name]/domain/repositories/` (interfaces only)

## A. Aggregate invariants — mandatory matrix

For **each business invariant**, document and test:

| Question | Required proof |
|---|---|
| What makes the invariant true? | Construct a valid aggregate with real domain objects. |
| What exact operation could violate it? | Exercise its public business method. |
| What happens at the boundary? | Verify exact allowed/denied cases. |
| What happens on rejection? | Verify typed error, **state unchanged**, version/identities unchanged, **no new events**. |
| What happens on success? | Verify new valid state, related dependent state, and correct event(s). |
| Can another method bypass it? | Test all public mutation paths that affect the invariant. |
| Is replay/retry possible? | Test idempotency/duplicate effects if this is a documented requirement. |

Focus on **invariant closure**: after *every* accepted command, the aggregate must remain valid. An invariant checked only during construction but broken by later methods is not enforced.

## B. Aggregates — high-value test scenarios

1. **Creation:** valid initial state and all creation-time invariants.
2. **Allowed transitions:** each meaningful `(state, command) -> state` transition.
3. **Forbidden transitions:** exact reason and no partial mutation.
4. **Boundary values:** threshold before/at/after, including prior accumulated state.
5. **Ownership:** entity within aggregate can only change through allowed aggregate operations.
6. **Consistency of related fields:** derived values, totals/counts, child membership, version, or audit data stay coherent.
7. **Repeated operations:** duplicate handling and idempotency if relevant.
8. **Sequence effects:** test sequences that reveal order-dependent state bugs, not only one isolated call.
9. **Failure atomicity:** rejection of step N must not leave steps 1..N-1 applied.
10. **Events:** one corresponding fact, correct payload, only after success; none on failed command.
11. **Concurrent business constraints:** if enforcement depends on concurrent transactions, validate using real persistence/concurrency tests, not by pretending a single aggregate instance is transactional.
12. **Reconstitution:** loading persisted state must preserve invariants; persisted old/invalid representations must be treated according to a documented policy.

### High-value test pattern — failure atomicity

The following is intentionally **a pattern, not a fabricated bounded context**. Replace `Aggregate`, `AttemptTransition`, and error/state names with the real API and business rule.

```go
func TestAggregate_AttemptTransition_RejectsForbiddenChangeWithoutSideEffects(t *testing.T) {
    // Arrange: create a REAL aggregate using legal public construction.
    aggregate := aRealAggregateInState(t, domain.StatePending)
    originalVersion := aggregate.Version()
    originalEvents := len(aggregate.PendingEvents())

    // Act: perform the disallowed business operation.
    err := aggregate.AttemptTransition(domain.StateForbidden)

    // Assert: observable business contract, including negative guarantees.
    require.ErrorIs(t, err, domain.ErrTransitionNotAllowed)
    require.Equal(t, domain.StatePending, aggregate.State())
    require.Equal(t, originalVersion, aggregate.Version())
    require.Len(t, aggregate.PendingEvents(), originalEvents)
}
```

Do **not** implement `Version`, `PendingEvents`, or getters just for tests; use whatever public contract the real domain already exposes. If an event queue can have pre-existing events, compare before/after rather than asserting globally empty.

### Strong positive outcome pattern

A success test should prove: starting state, business result, changed state, dependent invariant, exact event type/payload/occurrence time as applicable; avoid asserting incidental internal method calls. Event timestamps must come from an injected/fixed clock or an explicit input, never from wall-clock delays.

## C. Entities — test identity and behavior

- Two different entities with equal attributes remain distinct by identity where the domain requires it.
- Identity remains stable across lawful state changes.
- Entity methods respect consistency and ownership rules.
- Invalid lifecycle transitions or mutations are rejected without inconsistent intermediate state.
- No reflexive tests of every getter/setter.

## D. Domain Events — test facts, not framework publishing

- Correct event **type**, entity/aggregate ID, occurrence semantics, and essential business payload.
- Generated only when the underlying domain transition actually succeeds.
- No phantom event on rejected operations; no duplicate event if the command is idempotent.
- Event data does not unexpectedly change if source objects are subsequently mutated.
- Internal domain events vs versioned integration-event transformation are tested separately.
- Persistence, outbox, and delivery guarantees **cannot** be proven by a domain unit test; verify with integration tests.

## E. Domain Services — pure business behavior

- Prefer real input objects, no mocks.
- Validate decision tables and precedence of competing business rules.
- When rule conditions overlap, test the chosen precedence explicitly.
- If a service is pure, compare exact domain output/result and errors.
- If it requires an external collaborator, introduce a small interface at the appropriate boundary; a deterministic stub may be used **only for that external data**, never to fake the rule being tested.
- Do not test how many private helper methods executed.

## F. Domain Repository Policy — contract in domain, adapter in infrastructure

`[context-name]/domain/repositories/` contains **interfaces**, not SQL and not Go mocks. Interfaces generally need no standalone unit tests. Their contract is verified using the **real adapter implementation** against PostgreSQL, plus application tests against a fake that obeys the same required semantics.

Example contract obligations for a repository of one aggregate root:

- `Save -> FindByID` round-trip reconstitutes the same domain state, subject to documented normalization.
- `FindByID` missing record produces the domain's agreed not-found contract.
- Duplicate keys and optimistic-version conflicts are mapped to agreed errors.
- Related aggregate children are saved and loaded consistently.
- No partial writes when persistence fails halfway.
- The repository returns **domain aggregates**, never raw SQL row or `sqlc` types.

Do not create a mock of PostgreSQL and call that a repository integration test.

## Domain review checklist

- [ ] Every critical invariant has positive, negative, boundary, and failure-atomicity tests.
- [ ] All important public mutation paths enforce invariants.
- [ ] Meaningful aggregate transition sequences are covered.
- [ ] All tests use real entities, value objects, and aggregates.
- [ ] Domain errors are asserted by category/type (`errors.Is` or `errors.As`).
- [ ] Event emission and non-emission are verified against observable state.
- [ ] Time/IDs/randomness are controlled where they affect business outcomes.
- [ ] No tests exist solely to appease a line-coverage number.
