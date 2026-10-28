# Testing — Scope, Placement, and Executed Evidence

Source: guide §13. Tests specify business behavior and public contracts, not demonstrations of configured mock returns. Add them throughout each vertical slice and before moving behavior in a refactor.

## Select the boundary and evidence

| Scope | Use and assert | Location |
|---|---|---|
| Domain unit | Real values/aggregates/policies; valid, invalid, zero-value and boundary inputs, transitions, unchanged state/events after rejection | Beside the domain code |
| Application unit | Real domain objects and small port fakes; outcomes, persistence state, failure propagation and forbidden side effects | Beside the use case |
| REST/message unit | Binding/envelope validation, mapping, safe errors, delegation/cancellation with controlled dependencies | Beside the inbound adapter |
| Persistence integration | Actual selected engine, mappings, migrations, constraints, atomicity, concurrency, driver errors | `/test/integration/[context-name]/persistence/` |
| HTTP/message/ACL integration | Real dependencies and compatibility at the relevant boundary | `/test/integration/[context-name]/rest/`, `events/`, or `acl/` |
| E2E | Few critical full-system journeys through public boundaries | `/test/e2e/[context-name]/` or `/test/e2e/journeys/` |

## Organize idiomatically

- Unit tests use `*_test.go` beside production packages, grouped by feature/behavior/responsibility. Several test files may exercise one aggregate; no mandatory one-to-one source/test pairing.
- Prefer an external test package for public contracts where suitable; use the production package when internal-state assertions are justified. A package name declared in another directory does not grant unexported access.
- Root `/test` suites import accessible APIs. Account for nested `internal/` restrictions before relocating them. Do not export implementation details solely for tests or create a second module without a real lifecycle need.
- `httptest` with a fake use case can be unit-level; HTTP with real storage is integration. Test tools do not determine scope.
- Put fixture/golden files in suite-local `testdata/`; share helpers only across real consumers. No automatic test resources/transport directory mirror.
- Name behaviors clearly; use `t.Run` tables for equivalent partitions, not unrelated scenarios buried in a giant table. Mark helpers with `t.Helper()`.
- Review test files exceeding 150 physical lines by scenario/responsibility, retaining a cohesive suite with rationale rather than arbitrary fragmentation.

## Make tests sensitive to regressions

Use real domain objects, not mocks of value objects, entities, aggregates, pure policies, or the SUT. Assert meaningful successful, rejected, and boundary outcomes; coverage and `NoError` alone are insufficient. Verify interactions only when the absence/duplication of that effect would violate a contract.

Fakes must honor absence/conflict and aliasing semantics. A mutex around a map does not protect returned mutable pointers/slices. Copy state where the port requires isolation; do not let shared references accidentally persist failed mutations. A fake cannot prove database rollback or concurrency control.

Control clocks/IDs when relevant. Keep tests order-independent and avoid real external I/O in unit tests. For storage, use the actual selected production engine rather than assuming SQLite or memory proves another engine's guarantees. Container tooling is optional, not a mandatory technology choice.

## Execute suites explicitly

Tag integration files with `//go:build integration` and E2E files with `//go:build e2e`, followed by a blank line before `package`. CI must provision dependencies and execute each required tag. For the illustrative single-module layout:

```bash
# Fast unit checks; extend paths for other production packages if present
go test ./internal/... ./cmd/...
go test -race ./internal/... ./cmd/...
go vet ./...

# Actual storage/boundary guarantees
go test -tags=integration -count=1 ./test/integration/...

# Running system and critical flows
go test -tags=e2e -count=1 ./test/e2e/...
```

Adapt package paths to the actual repository; do not present nonexistent packages as executed checks. `go test ./...` does not run tagged suites without tags. Missing dependencies are a reported verification gap, not grounds to silently skip critical CI coverage.

Inspect targeted coverage; external suites may need `-coverpkg` for production packages. Add native fuzz tests for suitable parsers/invariants and project-adopted static checks where available. Do not invent a universal coverage percentage or claim the race detector proves absence of all races.

For failures, report the command, relevant output, and infrastructure/tooling prerequisites. For tagged suites, confirm actual execution rather than merely compiling their helpers. Real-engine tests should cover commit/rollback, optimistic or lock-based concurrency, cancellation, and state/outbox atomicity when applicable.

## Compatibility with the separate testing skill

The linked [go-tdb](../../../../test-driven-development-tdb/go-tdb/SKILL.md) remains a separate, unsynchronized document. It is **not a prerequisite or architectural authority** for this skill. Its domain/repositories placement, type-category domain tree, PostgreSQL/Koanf/YAML baseline, or other incompatible paths must not be imported as defaults here.

Its testing techniques may be consulted selectively only where compatible with the guide's consumer-owned ports, technology neutrality, and test placement. If both skills are requested and conflict, identify the contradiction explicitly and obtain a decision before changes that would alter those contracts; do not silently blend their structures. Updating this skill does not claim to repair that external document.

## Delivery evidence

Report checks run, passed/failed results, skipped checks with reasons, and residual risks. Keep repository tests separate from temporary snippet/syntax validation. A passing fake/unit suite must never be reported as successful database integration or E2E verification.
