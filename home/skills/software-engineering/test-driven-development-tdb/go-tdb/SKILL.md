---
name: go-tdb
description: Write production-grade tests for DDD bounded contexts in Go with Gin, PostgreSQL, Koanf, and TDD. Use real domain objects, contract-faithful fakes at application boundaries, real PostgreSQL integration tests, httptest for Gin, deterministic fixtures, race detection, fuzzing, and risk-based quality gates.
---

# Go + Gin — DDD Testing & TDD Implementation Guide

This skill is a complete, standalone, domain-first testing guide for enterprise Go applications and large modular monoliths organized by DDD bounded contexts. It defines rules, code patterns, checklists, and acceptance criteria.

Use it when implementing, reviewing, or refactoring tests for a Go monolith with repository **interfaces in `domain/repositories/`** and adapters in infrastructure.

For detailed examples and checklists, load the reference that matches the test layer. Do not front-load every reference.

## Baseline

- Go's `testing`, `t.Run`, `httptest`, standard assertions or `testify/require` if already adopted
- `go test -race`
- Native fuzzing where valuable
- Testcontainers for PostgreSQL
- Gin at HTTP boundaries
- Koanf v2 with YAML configuration

**Testing goal:** prove actual business invariants and public contracts using real domain objects. Substitute external dependencies only when appropriate; verify actual PostgreSQL behavior in integration tests.

**Main objective:** tests are *executable specifications of business rules*. A passing test is useful only if its assertions prove a meaningful observable contract and would fail after a plausible regression.

## Non-negotiable rules

1. **Test domain objects for real.** Never mock value objects, entities, aggregates, pure domain services, domain events, or the SUT.
2. **Prove business outcomes.** Assert invariants, allowed/forbidden transitions, state after failures, event semantics, and exact domain error categories. No `require.NoError`-only tests.
3. **Use no real I/O in unit tests.** No DB, network, queues, external services, or real clock; control time and IDs when relevant.
4. **Mock at architectural boundaries only.** Prefer a small fake or stub for `domain/repositories` in **application unit tests**; verify interactions only when they are part of the contract.
5. **Test the real PostgreSQL adapter against PostgreSQL** with Testcontainers, including SQL mappings, constraints, transactions, rollback, and concurrency—not a repository mock.
6. **Gin and Koanf stay outside the domain.** HTTP tests use `httptest`; configuration tests use controlled YAML bytes/providers and environment injection.
7. **One behavior per test.** Multiple cohesive assertions are fine. Use Arrange → Act → Assert. Keep tests deterministic, order-independent, and readable.
8. **Quality over coverage percentage.** Risk-driven scenarios, mutation sensitivity, and regression prevention take priority over line coverage.
9. **No arbitrary boilerplate.** Do not generate tests for trivial getters, generated code, empty constructors, or mocks that simply repeat configured values unless they enforce a real contract.
10. **Start from a rule.** If an invariant, valid transition, or failure contract is unknown, identify the requirement rather than inventing domain behavior.

## Standard naming and location

- Co-locate tests with production packages: `[context-name]/domain/.../some_file_test.go`, rather than a separate Java-style test source tree.
- Use `Test[Type]_[ShouldBehavior]When[Condition]` or `Test[Type]_[Method]_[Scenario]`; subtests use `t.Run("should ... when ...", ...)`.
- Use `*_test.go`. Keep integration tests discoverable with `//go:build integration` and/or an isolated integration suite.
- Prefer `package foo_test` for black-box public contracts; use `package foo` only when a justified package-internal contract must be tested.
- Prefer table-driven tests for equivalent input partitions, **not** to bury different business requirements in one table.

## Test implementation order

Follow the domain-first progression below and apply Go's package-level testing conventions.

| # | Topic | Reference |
|---|---|---|
| 1 | Value objects and enums | [references/value-objects-and-enums.md](references/value-objects-and-enums.md) |
| 2 | Commands and queries | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 3 | Domain events, aggregates, entities, domain services, repository contracts | [references/domain-model.md](references/domain-model.md) |
| 4 | Application command/query services and ACL | [references/application-and-acl.md](references/application-and-acl.md) |
| 4.5 | PostgreSQL adapters and transactions | [references/infrastructure-tests.md](references/infrastructure-tests.md) |
| 5 | Gin controllers, resources, transformers, errors, Koanf YAML | [references/interfaces-and-configuration.md](references/interfaces-and-configuration.md) |
| 6 | Test doubles and deterministic fixtures | [references/mocking-and-fakes.md](references/mocking-and-fakes.md) |
| 7 | Advanced domain test design | [references/deep-domain-testing.md](references/deep-domain-testing.md) |
| 8 | Coverage, race detection, and CI | [references/coverage-ci-and-checklist.md](references/coverage-ci-and-checklist.md) |
| 9 | RED → GREEN → REFACTOR workflow and review | [references/tdd-flow.md](references/tdd-flow.md) |

## Required four-question test contract

1. **Which business rule or external contract is at risk?**
2. **Which starting state and input activate that rule?**
3. **Which one main action exercises it?**
4. **Which observable facts prove correctness—and which facts must remain unchanged on failure?**

Do not add a test until those answers are concrete. Test public behavior, not private methods, implementation shape, function call counts, or incidental serialization details.

## Expected testing pyramid

**Many domain unit tests** → **targeted application/ACL unit tests** → **real repository integration tests** → **focused Gin contract tests** → **few end-to-end critical-flow tests**.

Domain correctness is not a mock interaction. Repository correctness is not an in-memory fake. HTTP correctness is not a real server requirement.

## Applicability

Use generic placeholders such as `[context-name]`, `[Aggregate]`, and `[ValueObject]` only to illustrate locations or patterns. Replace them with real business names and documented requirements. Do not invent bounded contexts, thresholds, domain errors, or APIs just to make example tests pass.

## Official documentation

- [Go testing](https://pkg.go.dev/testing)
- [Go fuzzing](https://go.dev/doc/security/fuzz/)
- [Go race detector](https://go.dev/doc/articles/race_detector)
- [Go coverage](https://go.dev/doc/build-cover)
- [Gin testing](https://gin-gonic.com/en/docs/testing/)
- [Testcontainers PostgreSQL module](https://pkg.go.dev/github.com/testcontainers/testcontainers-go/modules/postgres)
- [Koanf](https://github.com/knadh/koanf)

## Related skills

- [go-ddd](../../domain-driven-design-ddd/frameworks/go-ddd/SKILL.md) — the DDD bounded-context architecture tested by this guide.
- [data-design](../../data-design/SKILL.md) — schema, constraints, indexing, and migration design.
- [http-api-design](../../software-architecture/http-api-design/SKILL.md) — REST contracts, status codes, Problem Details, and pagination.
