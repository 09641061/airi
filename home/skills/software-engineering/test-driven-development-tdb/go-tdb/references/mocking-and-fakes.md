# Test Doubles, Domain Builders & Deterministic Fixtures

Read this before creating any fake, mock, spy, stub, or test-data builder.

## Double selection policy

| Double | Appropriate use | Do not use for |
|---|---|---|
| Real domain object | All Value Object, Entity, Aggregate, and Domain Service rules | Never replace with a test double |
| Dummy | Required but unused external parameter | Hiding an important missing collaborator |
| Stub | External dependency returns a fixed scenario | Simulating the domain result under test |
| Fake | Domain repository port for application-service orchestration | Claiming actual SQL/transaction correctness |
| Spy/Recorder | Contractually required outbound effect and payload | Verifying arbitrary internal calls |
| Mock | Strict external protocol, retry/idempotency/message ordering when required | Every interface/struct merely because it's an interface |

**Go default:** hand-written simple fakes/stubs are preferred over mock-generating frameworks, unless collaboration protocols are complex. No mocking tool is mandatory. Do not reflect a Java/Mockito habit into every Go test.

## Repository fake requirements

- Define the interface in `domain/repositories/`; the fake lives in `*_test.go`, a local testing helper, or a bounded-context test support package.
- Preserve domain object semantics, including not-found and version failures when needed.
- Do not accidentally persist changes just because the fake shares pointers with the object under test.
- Model failures intentionally: one specified fail point, not globally random failure.
- Fakes are not proof of SQL constraints, migrations, rollback, or isolation. Include real adapter tests for those.
- Avoid shared package-level fake state between tests.

## Builders / Mother objects

A good builder produces a **valid real aggregate by default** using public constructors, then changes only the relevant preconditions. It must not construct impossible domain states except through a dedicated reconstitution or migration API whose behavior is under test.

Recommendations:

- Prefer `validAggregate(t)` / `aggregateAtBoundary(t)` over `makeEverything(t, 47 args)`.
- Builder defaults are documented and deterministic; use stable IDs and fixed clocks.
- Expose expressive knobs for relevant domain state; avoid stringly-typed generic setters.
- Builders should not bypass invariants or mutate unexported fields via reflection/unsafe.
- If setup grows to dozens of irrelevant values, simplify the domain fixture API; do not force every test to reconstruct an entire object graph.
- Reuse within **one bounded context**. Do not create a universal cross-context fixture package that couples domains.

## Clock, IDs, randomness

Where time affects a rule, use an explicit `time.Time` input or a small injected `Clock` interface. For unit tests, a fixed clock returns an unchanging value:

```go
type fixedClock struct{ now time.Time }
func (c fixedClock) Now() time.Time { return c.now }
```

- Avoid `time.Now()` and wall-clock waits in assertions; never sleep to make tests pass.
- Compare instants and business timezone interpretations according to the domain contract.
- Use fixed IDs, deterministic sequence generators, or seeded randomness when IDs affect output.
- Prefer explicit cases for business boundaries; use fuzzing for additional exploration, not as a replacement.

## Interaction assertions policy

Verify collaborator interactions **only if not making that interaction is a business bug** (for example, suppressing duplicate publication, emitting one integration event, or persisting an audit record). Prefer checking the data or state that makes the effect meaningful:

**Weak:** `mockRepo.AssertCalled("Save", anything)`.

**Strong:** after the command, the repository contains an aggregate with the correct state, no forbidden effect occurred, and any mandatory integration event has the correct ID/payload and count.

Do not over-specify exact call order, private helper calls, unused optional methods, or arbitrary `NoMoreInteractions` equivalents.

## Red flags

- Fakes that return identical pointers to production aggregate instances.
- Mocks of every interface, including domain pure-policy interfaces.
- Helpers that call production methods to compute the expected value.
- Shared mutable global fixtures; implicit dependence on test order.
- Dynamic timestamps, random data, or real network calls in unit tests.
- Using a SQL mock as evidence that the repository persists real data correctly.

## Checklist

- [ ] No mocks of domain entities, aggregates, or value objects.
- [ ] At least one observable business assertion per test.
- [ ] Fakes preserve necessary repository contract semantics.
- [ ] Deterministic builders create valid states.
- [ ] Fixtures do not depend on global mutable state.
- [ ] External interactions checked only when business-visible.
