# Deep Domain Test Design — How to Catch Real Business Bugs

This chapter defines the **quality standard** for large, long-lived DDD monoliths. Writing one green test per method is not enough.

## 1. Inventory rules before writing code

For every bounded context, build an **invariant catalog** from requirements and production domain behavior:

| Rule ID | Invariant / behavior | Owning aggregate or VO | Allowed boundary | Forbidden boundary | State on failure | Events / side effects |
|---|---|---|---|---|---|---|
| `[R-001]` | `[business rule]` | `[Aggregate]` | `[valid case]` | `[invalid case]` | `[unchanged facts]` | `[event contract]` |

Do not invent rule IDs, thresholds, or error names when requirements are missing. Ask for the contract or clearly mark missing decisions. A test that proves an invented rule can actively harm the codebase.

## 2. Test the invariant, not the method body

For each rule, cover:

1. **Valid witness:** smallest realistic valid scenario.
2. **Invalid witness:** precise scenario that violates the rule.
3. **Boundary witness:** just before/at/just after a threshold where applicable.
4. **Stateful witness:** prior successful actions change what must now be rejected.
5. **Failure atomicity:** no partial state change; unchanged IDs/version/events.
6. **Alternative-path witness:** invariant still holds through every other public mutation entry point.
7. **Sequence witness:** a meaningful sequence of operations preserves it.
8. **Event witness:** success emits exact documented event; rejection does not.

**Do not duplicate eight tests if the domain has no corresponding dimensions.** The matrix is a risk checklist, not a quota.

## 3. Model state machines explicitly when relevant

List reachable states, allowed transitions, and forbidden transitions; prove reachability and forbidden behavior. Include operations performed twice, operations out of order, and transitions near expiration/threshold times when business rules require them.

A transition test should check **both the new state and the invariants that justify that state**. A forbidden transition test should check the exact domain error and complete lack of new effects.

## 4. Negative guarantees and rollback semantics

For aggregate rejection, verify *all relevant publicly observable data* remained unchanged, not merely the status. For multi-entity writes, verify actual rollback against PostgreSQL; a fake cannot prove atomic commit.

If a domain operation is intentionally partially successful (documented compensation model), test the specified partial outcome, **not** blanket rollback.

## 5. Metamorphic / property tests

Use properties only when a domain law is known:

- **Validity preservation:** valid initial state + permitted operation sequence ⇒ valid final state.
- **Idempotency:** applying the same idempotent command twice yields the same business outcome and no duplicate external event.
- **Conservation:** sum/quantity/count remains equal to the domain-defined conservation rule before and after an operation.
- **Order independence:** only when operations are *specified* as commutative; do not assert it indiscriminately.
- **Round-trip:** persist + restore retains the contractually relevant state.

If an invariant has no public `Validate` method, observe relevant domain facts instead of adding a test-only validator to production.

## 6. Native Go fuzzing

Good fuzz targets are pure, fast, deterministic, and domain-relevant: parsers, value objects, calculations with well-defined bounds, non-panicking invalid input handling, and a finite set of legal state transitions.

```go
// Template: the property must be replaced by an actual documented invariant.
func FuzzValueObject_ConstructorPreservesInvariant(f *testing.F) {
    f.Add(int64(0))
    f.Add(int64(1))
    f.Add(int64(-1))

    f.Fuzz(func(t *testing.T, raw int64) {
        value, err := domain.NewValueObject(raw)
        if err != nil { return } // invalid input is an allowed outcome
        if !domain.ValidAccordingToPublishedRule(value) {
            t.Fatalf("accepted invalid domain value: %v", raw)
        }
    })
}
```

The `ValidAccordingToPublishedRule` call is **illustrative**; never write a test that uses the same implementation as the constructor to calculate its expected result (a shared bug could fool both). Derive a property independently from the rule. Fuzz tests must not call a DB or mutate global state. Minimized failing inputs become regression fixtures.

## 7. Mutation sensitivity (the most useful self-test)

Ask: **if the production code had one of these bugs, which test would fail?**

| Plausible mutant/bug | Test that should detect it |
|---|---|
| `<` changed to `<=` | Exact-boundary acceptance and rejection. |
| Validation branch removed | Invalid witness with a specific domain error. |
| State updated before failure returned | Failure-atomicity snapshot assertions. |
| Duplicate event emitted | Exact event count and content assertions. |
| Event omitted entirely | Success-event contract assertion. |
| Wrong aggregate ID in event | Payload identity assertion. |
| Changed rounding direction | Exact precision test at a rounding boundary. |
| Repository `Save` no longer called | Assert persisted state from a contract-faithful fake. |
| Stale version overwrites latest | Real PostgreSQL optimistic-concurrency integration test. |
| Unit-of-work commits partial data | Real rollback/outbox atomicity integration test. |
| ACL not-found mapped to success | Consumer state and typed error assertion. |

**Practical exercise:** temporarily inject a localized bug (or use a vetted mutation tool) and run the targeted test. If the test stays green, its oracle/assertions are too weak. Restore original code immediately. Use automated mutation tooling only after evaluating its maintenance/status and supported Go syntax; no universal Go mutation tool is required.

## 8. Test priority by risk

**Critical:** identity/authorization boundaries, irreversible lifecycle transitions, resource ownership, uniqueness, monetary/precision rules, concurrent updates, external side effects, and outbox/integration guarantees.

**High:** complicated decision tables, timezone/expiry rules, multi-step aggregate changes, schema compatibility, and critical query pagination.

**Normal:** simple policies and transport mapping where a regression is externally visible.

**Low value:** simple getters, plain struct assignments, autogenerated SQL code, generated OpenAPI structs, and tests that assert only that `nil` was returned.

## 9. Reviewer rubric (score each critical test)

Mark each as **pass or fail** (not subjective “looks good”):

- A documented business rule is named in the test.
- The initial state matters to the rule.
- The action traverses the real domain implementation.
- The assertion would fail on a plausible business bug.
- Forbidden operations demonstrate unchanged state and no invalid event.
- No mock controls the domain outcome.
- Setup is deterministic and the expected output is independent of production calculation.
- Scope matches the guarantee (unit vs integration).

A suite that fails these checks is incomplete even with high coverage.
