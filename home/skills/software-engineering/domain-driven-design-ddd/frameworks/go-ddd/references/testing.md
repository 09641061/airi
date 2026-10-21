# Testing Requirements

Tests are executable specifications of business behavior and public contracts—not demonstrations that mocks can return prearranged values.

## Test by boundary

- **Domain unit tests:** use real Value Objects, Entities, Aggregates, and Domain Services. Cover invariants, valid/invalid transitions, boundary conditions, event correctness, rule-required idempotency, and unchanged state after rejected operations.
- **Application unit tests:** use small fakes/stubs for repository or ACL ports only where needed to control boundary outcomes. Assert business-visible results and forbidden side effects; avoid tests that only assert arbitrary call counts.
- **Persistence integration/contract tests:** exercise the actual selected engine. Verify mapping, uniqueness, consistency, concurrency, and driver-specific error handling. An in-memory fake is not proof of production-engine semantics.
- **REST tests:** use Gin and `httptest` for binding, validation, response/status mapping, and request cancellation propagation.
- **Cross-context tests:** verify ACL translations, public provider contracts, missing data, failures, and timeouts.

## Quality guidance

- Test meaningful positive, negative, and boundary cases for critical domain rules.
- Do not mock Value Objects, Entities, Aggregates, Domain Services, or the system under test.
- Rejected commands must not partially mutate aggregates or emit success events.
- Prefer observable outcomes and stable public contracts over implementation details.
- Treat coverage as an inspection aid, not proof of correctness.
- Use `go test ./...` and `go test -race ./...`; inspect targeted coverage. Add native fuzz tests for suitable parsers/invariants and mutation testing for high-risk rules when beneficial.
- Keep tests deterministic, and control clocks/IDs when they affect behavior.

Testing frameworks, test databases, containers, and external test tools should follow the selected technology and project constraints; no particular engine or library is mandatory.
