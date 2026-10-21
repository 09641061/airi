# Commands & Queries — Input Contracts, Not Fake Domain Rules

**Production locations (mirroring the Go DDD guide):**

- `[context-name]/domain/model/commands/`
- `[context-name]/domain/model/queries/`

Commands express **intent to change state**; queries request information without mutation. Plain Go input structs may need **few or no direct unit tests**. Do not manufacture tests for data-only types merely to inflate coverage.

## Commands — test only observable contracts

- Constructor/validation rejects missing or contradictory required business inputs if validation is owned here.
- Cross-field conditions are rejected when explicitly part of the command contract.
- Important Value Objects are preserved and converted without losing information.
- Command input is not transport-dependent (`gin.Context`, JSON tags, status codes, or SQL rows must not appear in the domain model).
- If command structs are unvalidated data carriers, prove the business rule at the **application or aggregate**, not by repeating a test for every field.

## Queries — test only real query semantics

- Invalid page sizes, unsupported sort keys, and contradictory filters are rejected **where the query contract owns validation**.
- Boundaries and defaults (max page size, cursor requirements) have concrete expected values.
- Optional filters distinguish absent from explicitly specified values where required.
- Valid filter sets produce the correct contract; query service and SQL result semantics are tested in their own layers.
- Queries must not mutate aggregate state or perform side effects.

## What not to test

```go
func TestCommand_Field(t *testing.T) {
    cmd := domain.Command{Field: "x"}
    require.Equal(t, "x", cmd.Field) // Reject: merely restates Go assignment.
}
```

Do not test DTO → Command mapping multiple times across request, command, and service tests unless each layer owns a separate rule. Test the mapping once at the relevant boundary.

## Checklist

- [ ] Tests exist only for non-trivial input constraints or meaningful query rules.
- [ ] Business invariants remain tested in aggregates/value objects.
- [ ] Exact invalid cases and error contracts are asserted.
- [ ] No useless field-copy or zero-value ceremony tests.
- [ ] No mocks of commands or queries.
