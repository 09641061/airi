# TDD Workflow & Anti-Pattern Review

The practical development loop is **TDD (Test-Driven Development): RED → GREEN → REFACTOR**. Testing also applies when reviewing existing code that was not originally developed test-first.

## Recommended workflow

1. **Read the business rule** and determine the owning bounded context and aggregate.
2. **Write a rule contract**: preconditions, action, permitted/forbidden outcomes, invariant, and event side effects.
3. **Choose the test type**: pure domain, application orchestration, DB integration, or Gin HTTP boundary.
4. **RED:** write one failing test with a meaningful assertion that proves the behavior is currently missing or incorrect.
5. **GREEN:** implement the minimum domain behavior necessary to make the test pass—do not satisfy it by teaching a mock to return the desired result.
6. **REFACTOR:** improve the design without changing published behavior; keep tests at public seams.
7. **Add nearby risks:** exact boundaries, another invalid transition, stateful sequences, error atomicity, and event correctness.
8. **Use real objects** and minimal deterministic builders/fakes at external ports only.
9. **Run the targeted suite**, then full fast tests, race detection, and affected DB tests.
10. **Challenge assertions:** remove a guard, flip a comparison, or suppress an event temporarily; identify which test goes red.
11. **Keep scope clean:** no application/infra dependency in the domain package.
12. **Ship only with demonstrated guarantees**; record unresolved rules/DB cases rather than inventing them.

## Example: distinguish a worthless test from a real domain test

**Reject** (test establishes no correct business outcome):

```go
func TestAggregate_Execute(t *testing.T) {
    mock := new(MockAggregate)
    mock.On("Execute").Return(nil)
    require.NoError(t, mock.Execute())
}
```

**Required shape** (template; use real domain terminology):

```go
func TestAggregate_RejectsForbiddenTransitionWithoutMutation(t *testing.T) {
    // Given: REAL aggregate in a legal prior state.
    aggregate := realAggregateWithPreconditions(t)
    beforeStatus := aggregate.Status()
    beforeRevision := aggregate.Revision()
    beforeEventCount := len(aggregate.PendingEvents())

    // When: attempt a transition forbidden by a specific domain rule.
    err := aggregate.ApplyForbiddenTransition()

    // Then: typed domain rejection and NO new effects.
    require.ErrorIs(t, err, domain.ErrTransitionNotAllowed)
    require.Equal(t, beforeStatus, aggregate.Status())
    require.Equal(t, beforeRevision, aggregate.Revision())
    require.Len(t, aggregate.PendingEvents(), beforeEventCount)
}
```

Neither `realAggregateWithPreconditions` nor the placeholder methods are prescribed production APIs. The real test must describe **why** that transition is prohibited and assert every important business invariant in the actual aggregate.

## Review questions before approval

- Would the test still pass if the main domain rule were deleted?
- Would it detect an off-by-one error at a documented threshold?
- Would it detect a rejected operation that mutated one field before returning an error?
- Would it detect a missing or duplicate domain event?
- Does the expected value come independently from requirements, not copied from implementation?
- Did we mock anything that is itself responsible for enforcing the rule?
- Is the right guarantee checked at the right layer (unit vs real PostgreSQL)?
- Would the test remain valid after refactoring internal methods, replacing Gin routing helpers, or changing SQL generation?

If the first four answers are “yes, it would still pass,” the tests are not sufficiently protective.

## Common pitfalls to block in code review

1. Mocked aggregate/domain service result used as the assertion oracle.
2. `require.NoError` without asserting business state.
3. Testing only nominal path; no rejected transitions and no boundaries.
4. Failure test asserts `err != nil` but not `errors.Is` and unchanged state.
5. Fake repository shares pointers and silently persists mutations.
6. SQL mock used instead of running migrations and SQL against PostgreSQL.
7. Test compares a calculation against the same production function.
8. Random test inputs/time assumptions that produce flaky tests.
9. `t.Parallel()` with `t.Setenv` or shared mutable global settings.
10. Increasing coverage with trivial getter/field-copy tests.
11. OpenAPI response contract not actually asserted from the Gin handler.
12. A critical integration test is tagged but never run in CI.

## Final decision

**Accept tests only when they defend a named invariant, failure contract, observable integration guarantee, or published API boundary.** Mock collaboration is not business correctness; code coverage is not an oracle; a real domain object exercised under realistic constraints is the default.
