# Coverage, Race Detection, CI, Quality Gates & Final Checklist

## Recommended Go toolchain

- Built-in `testing` and `t.Run`; `testify/require` optional for expressive assertions.
- Built-in `httptest` for Gin routes.
- Built-in `go test -race` to detect data races in executed code.
- Built-in Go fuzzing for rule-based, pure inputs.
- `go test -coverprofile` and `go tool cover` for execution coverage.
- `go vet`; formatter (`gofmt`), linter if the team has one.
- Testcontainers for PostgreSQL integration.

**Do not invent library/version mandates.** Use tested organization-approved Go and dependency versions pinned in `go.mod`/`go.sum`.

## Commands

```bash
# Fast feedback (default: only unit tests, because integration tests are build-tagged)
go test ./...

# Re-run unit tests uncached to reveal order/flakiness
go test -count=1 ./...

# Detect data races in exercised code
go test -race -count=1 ./...

# Inspect execution coverage for fast tests
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
# Optional visual report:
go tool cover -html=coverage.out

# Real PostgreSQL integration tests; includes untagged tests too
go test -tags=integration -count=1 ./...

# Fuzz a selected target in its package (not a whole repo at once)
go test -run='^$' -fuzz=FuzzValueObject -fuzztime=30s ./internal/[context-name]/domain/model/valueobjects

go vet ./...
```

**Note:** replace placeholder paths before invoking. `-race` finds races on **executed** code; it does not prove a program is race-free. Fuzzing discovers counterexamples; it cannot prove a domain law universally. Coverage shows executed statements, not how strong the assertions are.

## CI lanes for large monoliths

| Lane | Typical cadence | Must check |
|---|---|---|
| PR fast | Every PR | Format/static checks; targeted and all fast unit tests; meaningful domain assertions. |
| Race | Every PR or regular CI depending on runtime | Race detector over unit/component tests that exercise concurrency. |
| PostgreSQL integration | Every PR for touched persistence / main CI | Real migrations and repository contracts, transaction atomicity. |
| Domain fuzz | Short seeded PR run; longer scheduled run | Known corpus and chosen domain laws; preserve failing corpus. |
| Critical-flow E2E | Release pipeline / focused PRs | Essential cross-context business flows. |
| Mutation review | High-risk changes or periodic | Targeted manual or tool-assisted mutation checks on domain rules. |

An integration suite behind `//go:build integration` must be **actually executed by CI**. Hiding it behind a tag without running it provides no protection.

## Coverage policy (risk-based)

- Track domain/application separately from adapters/controllers if reporting allows.
- Require a reviewed **rule-to-test matrix** for high-risk aggregates and value objects.
- Use numeric thresholds only if a team explicitly adopts them; **100% lines** can still miss a fundamental invariant.
- Coverage must not increase by adding trivial tests that repeat assignments or mocks.
- Every new critical bug fix includes a failing regression test first.
- For materially changed domain rules, reviewers should identify the **specific assertion** that would fail after removing that rule.
- If an integration contract cannot run in CI, mark the risk open rather than silently treating a mocked test as equivalent.

## Final bounded-context checklist

### Domain

- [ ] Each critical invariant has valid/invalid/boundary/failure-state proofs.
- [ ] Aggregate operations and meaningful transition sequences tested.
- [ ] Negative guarantees tested: no partial changes, no invalid events.
- [ ] Real value objects/entities/aggregates used, never mocks.
- [ ] Domain services test real decision logic and rule precedence.
- [ ] Time/precision/IDs are deterministic when relevant.

### Application and ACL

- [ ] Command success proves resulting persisted business state via a contract-faithful fake.
- [ ] Failed command leaves fake persisted state unchanged.
- [ ] Repository and ACL errors are translated meaningfully.
- [ ] Idempotent and retry-prone effects are tested where required.
- [ ] No fake is mislabeled a database-transaction test.

### Infrastructure and HTTP

- [ ] PostgreSQL adapter tested against real PostgreSQL plus migrations.
- [ ] Round-trip, constraints, conflicts, rollback/outbox covered where relevant.
- [ ] Gin request validation, error mapping, and response schema verified with `httptest`.
- [ ] Koanf YAML/env precedence and validation have dedicated tests.
- [ ] No secrets leak in errors/logs.

### Reliability and CI

- [ ] Tests deterministic, independent, and CLI-runnable.
- [ ] Race detection enabled at an agreed cadence.
- [ ] Integration tests actually run in CI.
- [ ] Fuzz seeds, regression tests, and boundary cases retained.
- [ ] Assertion quality reviewed independently of percentage coverage.
- [ ] No `t.Skip` without a tracked, actionable reason for an intentionally excluded critical test.
