# Coverage, CI, Commands, and Checklists

## Coverage expectations

Coverage is a **signal**, not a goal. Don't write meaningless tests to reach 100%. Focus on:

- Business rules
- Validation rules
- Failure paths
- Critical use cases
- Important persistence logic
- Public API behavior

100% coverage does not guarantee correctness.

### Recommended minimum coverage by layer

| Layer | Target | Why |
|-------|--------|-----|
| Value objects | High | They protect invariants; every validation is a test |
| Aggregates / entities | High | They enforce business rules; every rule is a test |
| Domain services | High | They are pure logic |
| Application services | High | They orchestrate the use case |
| ACL services | High | They translate errors and shape data |
| REST controllers / handlers | Medium | Test routing, parsing, status codes; don't re-test domain rules |
| Repository adapters | Integration tests | The unit-testable parts are tiny; the SQL is the boundary |
| Cross-cutting (logging, middleware) | Low | Smoke tests are enough |

## Continuous integration

Every pull request should run:

```bash
go test ./...
go test -race ./...
```

Optionally:

```bash
go vet ./...
go test -cover ./...
```

For projects with integration tests:

```text
start PostgreSQL (testcontainers or a service container)
run migrations
go test -tags=integration ./...
```

The integration test stage is usually a separate CI job — it takes longer and needs a real database.

### Common CI patterns

- **GitHub Actions**: separate jobs for `unit` and `integration`; the integration job caches the testcontainers image and runs `go test -tags=integration ./...`.
- **Local pre-push hook**: run `go test -race ./...` before pushing. Catches race conditions before they reach CI.

## Test execution commands

```bash
# Run everything
go test ./...

# With race detection
go test -race ./...

# With coverage
go test -cover ./...

# Specific package
go test ./internal/order/domain/...

# Specific test
go test -run TestOrderConfirm ./internal/order/domain/...

# Verbose
go test -v -run TestOrderConfirm ./internal/order/domain/...

# Integration tests only
go test -tags=integration ./...

# Benchmarks
go test -bench=. -benchmem ./...

# Mutation testing (PIT-style for Go)
# (no widely adopted tool; see "Mutation testing" section below)
```

## Test file structure

Keep tests next to the code:

```
order/
  domain/
    order.go
    order_test.go
  application/
    service.go
    service_test.go
  infrastructure/
    postgres.go
    postgres_integration_test.go    # //go:build integration
  interfaces/
    http.go
    http_test.go
```

Don't create `tests/unit/`, `tests/integration/`, `tests/domain/`, `tests/application/`, `tests/repositories/` trees unless the project has a strong reason. Go works well with tests beside the implementation.

## Race detection

For concurrent code, regularly run:

```bash
go test -race ./...
```

Especially in tests that use:

- goroutines
- channels
- shared memory
- workers
- caches
- background jobs

A passing unit test does not prove concurrent code is race-free. The race detector instruments memory accesses at runtime; a 30-second run with `-race` catches issues that a 30-minute run without it misses.

## Benchmarks

Don't benchmark everything. Benchmark only when performance matters.

```go
func BenchmarkOrderCalculation(b *testing.B) {
    order := createLargeOrder()
    for b.Loop() {
        _ = order.Total()
    }
}
```

Use `b.Loop()` (Go 1.24+) instead of `for i := 0; i < b.N; i++` so the benchmark doesn't include the loop overhead.

Run:

```bash
go test -bench=. -benchmem ./...
```

Always benchmark before and after an optimization. Without a baseline, the "optimization" is a guess.

## Coverage commands

```bash
# Total coverage
go test -cover ./...

# Per-function coverage
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out

# HTML report
go tool cover -html=coverage.out -o coverage.html
```

Set a coverage gate in CI only if the team can commit to maintaining it:

```bash
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out | awk '$1 != "total:" { cov += $3 } END { if (cov < 80) exit 1 }'
```

But remember: a test that asserts nothing raises coverage. Coverage is a floor, not a guarantee.

## Common pitfalls

1. **Don't connect to a real database in unit tests.** Use fakes for repository ports; use integration tests for persistence.
2. **Don't mock the value object, the aggregate, or the class under test.** Use real domain objects to preserve domain behavior.
3. **Don't use mocking libraries.** Hand-roll a fake. Mocks add refactor hostility and implementation coupling.
4. **Don't use `pgxmock` / `sqlmock` / GORM mock mode.** The integration test is the only honest test of a database adapter.
5. **Don't test only happy paths.** Always test invalid data, edge cases, and failure scenarios.
6. **Don't test implementation details.** Test behavior, outcomes, errors, and meaningful interactions.
7. **Don't depend on test execution order.** Each test must be independent. Use `t.Parallel()` for tests that don't share state.
8. **Don't ignore failing tests.** Fix the behavior or fix the test — never `t.Skip()` to make CI green.
9. **Don't over-test simple helpers.** If a function is a one-liner with no branching, the test adds noise.
10. **Don't unit-test the driver.** The integration test runs against real PostgreSQL. Mocking the driver is testing a parallel universe.

## Final bounded-context checklist

```text
DOMAIN
[ ] Value objects have valid and invalid creation tests
[ ] Domain errors are returned and tested with errors.Is
[ ] Aggregates protect invariants
[ ] Aggregates test valid and invalid state transitions
[ ] Domain services test pure policies / calculations
[ ] No database, no HTTP, no mocks in domain tests
[ ] Time is injected when a rule depends on it

APPLICATION
[ ] Command services test successful write flows
[ ] Command services test business rule failures
[ ] Command services verify Save is not called on rule failure
[ ] Command services verify Save is not called on not-found
[ ] Query services test found and not-found results
[ ] Query services do not modify state
[ ] ACL services test external lookup, empty response, and failure cases
[ ] Fakes are hand-rolled in the test package

INFRASTRUCTURE
[ ] PostgreSQL adapter tested against real database via testcontainers
[ ] Not-found is translated to domain.ErrX
[ ] At least one constraint is tested (unique, FK, check)
[ ] Transaction commit and rollback are exercised
[ ] No pgxmock, sqlmock, or GORM mock mode

INTERFACES
[ ] Handlers test expected HTTP status codes (200/201/400/404/409/422/500)
[ ] Handlers test request parsing and validation
[ ] Handlers test error response is application/problem+json
[ ] Handlers do not retest domain rules
[ ] OpenAPI is updated for every new endpoint

TEST QUALITY
[ ] Tests follow Arrange, Act, Assert
[ ] Tests use behavior-based names (TestOrderConfirm, not Test1)
[ ] Tests are independent (no execution order dependency)
[ ] Tests are deterministic (no time.Now, no rand, no sleep)
[ ] Tests are fast (sub-second for the unit suite)
[ ] Tests do not use real infrastructure in the unit suite
[ ] go test ./... passes
[ ] go test -race ./... passes
[ ] No mocking framework, no interface invented for tests
[ ] Coverage report is generated and reviewed
```

## Definition of done for a feature

A feature is complete when:

- [ ] Domain tests cover the new business behavior
- [ ] Domain tests cover the important failure cases
- [ ] Application tests cover the orchestration (success and rule failures)
- [ ] Infrastructure integration tests cover the adapter
- [ ] HTTP tests cover the new endpoint
- [ ] OpenAPI is updated
- [ ] `go test ./...` passes
- [ ] `go test -race ./...` passes
- [ ] No mocking framework was introduced
- [ ] No interface was invented solely for tests

## Mutation testing (optional)

Mutation testing verifies that your tests would catch small changes in production code. For Go, the most practical option is [`go-mutesting`](https://github.com/avito-tech/go-mutesting) (limited maintenance) or writing project-specific mutators with [`go/ast`](https://pkg.go.dev/go/ast).

Use mutation testing as a **spike**, not a default CI step:

- Run it once per bounded context, not on every commit.
- Look at surviving mutants to find tests that don't actually assert behavior.
- Fix the tests, not the production code.

Mutation testing is slow and noisy. It's a tool for finding dead assertions, not a quality gate.
