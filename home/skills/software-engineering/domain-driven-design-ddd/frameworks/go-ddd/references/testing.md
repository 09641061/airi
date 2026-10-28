# Testing Requirements

Tests are executable specifications of business behavior and public contracts — not demonstrations that mocks can return prearranged values.

## Test by boundary

- **Domain unit tests:** use real Value Objects, Entities, Aggregates, and Domain Services. Cover invariants, valid/invalid transitions, boundary conditions, event correctness, rule-required idempotency, and unchanged state after rejected operations.
- **Application unit tests:** use small fakes/stubs for repository or ACL ports only where needed to control boundary outcomes. Assert business-visible results and forbidden side effects; avoid tests that only assert arbitrary call counts.
- **Persistence integration/contract tests:** exercise the actual selected engine. Verify mapping, uniqueness, consistency, concurrency, and driver-specific error handling. An in-memory fake is not proof of production-engine semantics.
- **REST tests:** use Gin and `httptest` for binding, validation, response/status mapping, and request cancellation propagation.
- **Cross-context tests:** verify ACL translations, public provider contracts, missing data, failures, and timeouts.

## Go test idioms

- **Table-driven tests:** express scenarios that share setup as a table of cases and run each with `t.Run(name, ...)`, so a failure reports the case that broke instead of a line number.
- **Assertion helpers:** mark helper functions with `t.Helper()` so the reported line is the caller's.
- **Golden files:** keep expected payloads under `testdata/` and compare with `os.ReadFile` when the exact output matters.
- **Static checks:** run `go vet ./...` (plus `staticcheck` when the project uses it) as part of the quality gate.

```go
func TestEnrollmentConfirm(t *testing.T) {
	cases := []struct {
		name    string
		status  Status
		wantErr error
	}{
		{name: "confirms pending", status: StatusPending},
		{name: "rejects confirmed", status: StatusConfirmed, wantErr: ErrAlreadyConfirmed},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			e := &Enrollment{id: "e-1", status: tc.status}
			err := e.Confirm()
			if !errors.Is(err, tc.wantErr) {
				t.Fatalf("Confirm() error = %v, want %v", err, tc.wantErr)
			}
		})
	}
}
```

## Quality guidance

- Test meaningful positive, negative, and boundary cases for critical domain rules.
- Do not mock Value Objects, Entities, Aggregates, Domain Services, or the system under test.
- Rejected commands must not partially mutate aggregates or emit success events.
- Prefer observable outcomes and stable public contracts over implementation details.
- Treat coverage as an inspection aid, not proof of correctness.
- Use `go test ./...` and `go test -race ./...`; inspect targeted coverage. Add native fuzz tests for suitable parsers/invariants.
- Keep tests deterministic, and control clocks/IDs when they affect behavior.

Testing frameworks, test databases, containers, and external test tools should follow the selected technology and project constraints; no particular engine or library is mandatory.

For the Go testing conventions in depth (fixtures, fakes, integration setup, CI gates), see the Go testing skill: [go-tdb](../../../../test-driven-development-tdb/go-tdb/SKILL.md).

## Checklist

- [ ] Critical domain invariants have positive, negative, and boundary tests.
- [ ] No mocks for Value Objects, Entities, Aggregates, or the system under test.
- [ ] Rejected commands do not partially mutate aggregates or emit success events.
- [ ] Repositories are tested using the selected real persistence technology.
- [ ] Tests verify outcomes and public contracts, not arbitrary call counts.
- [ ] Coverage numbers are not treated as proof of correctness.
- [ ] Scenarios that share setup are expressed as named table-driven cases.
