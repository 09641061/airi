---
name: go-tdb
description: Write Go tests for a Domain-Driven Design bounded context using TDD — value objects, aggregates, domain errors, application services, ACL facades, REST handlers, and PostgreSQL persistence. Uses stdlib testing + httptest + testcontainers, hand-rolled fakes instead of mocking frameworks, behavior-driven naming, and inside-out RED→GREEN→REFACTOR flow. Use whenever asked to write, review, or scaffold tests for a Go service following DDD/hexagonal patterns.
---

# Go Bounded Context Test-Driven Development

Recommended stack: Go stdlib `testing`, `httptest`, `testcontainers-go` for PostgreSQL, hand-rolled fakes for ports. **No mocking frameworks, no `pgxmock`, no `sqlmock`, no GORM mock mode.**

The goal is not to maximize test count. The goal is to design reliable code through small feedback loops.

> **Write the behavior first. Implement the minimum code required to make it work.**

## Core cycle: RED → GREEN → REFACTOR

```text
RED
 ↓
GREEN
 ↓
REFACTOR
 ↓
repeat
```

- **RED** — write a test that describes the expected behavior. The test must fail for the correct reason.
- **GREEN** — write the minimum implementation required to make the test pass. Do not optimize prematurely.
- **REFACTOR** — improve the design without changing behavior. All tests must stay green.

## Core conventions (apply to every layer)

- **Tests live next to the code they exercise**: `order.go` ↔ `order_test.go` in the same package. Don't create `tests/unit/`, `tests/integration/` trees unless the project has a strong reason — Go's convention is co-location.
- **Test packages** are `package <thing>_test` (external) when you want a black-box view, or `package <thing>` (internal) only when you need access to unexported helpers. Prefer the external `_test` package; it forces the test to use only the public API, which is what production callers see.
- **Naming:** `Test<Order><Behavior>` — e.g. `TestOrderConfirm`, `TestConfirmedOrderCannotBeConfirmedAgain`, `TestNewMoneyRejectsNegativeAmount`. The name should explain what failed without opening the file.
- **Structure:** every test follows **Arrange / Act / Assert** — one behavior per test, one method call under Act, no unrelated assertions.
- **Test behavior, not implementation.** A refactor that preserves observable behavior must not break the test. Don't test private methods, internal variable names, or call counts.
- **Don't mock the value object, the aggregate, or the class under test.** Mock only the dependencies that live outside the package you're testing.
- **Don't create interfaces only for tests.** If a port already exists in the domain, the test uses the port. If a port doesn't exist, write a small fake of the concrete type instead of inventing a new abstraction.

## Build order

Follow this order — each step builds on the previous one. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Value objects & domain errors (RED → GREEN → REFACTOR) | [references/domain-tests.md](references/domain-tests.md) |
| 2 | Aggregates, entities, domain services | [references/domain-tests.md](references/domain-tests.md) |
| 3 | Application services (use case orchestration with fakes) | [references/application-tests.md](references/application-tests.md) |
| 4 | Infrastructure adapters (real PostgreSQL via testcontainers) | [references/infrastructure-tests.md](references/infrastructure-tests.md) |
| 5 | REST handlers (`httptest`) | [references/interfaces-tests.md](references/interfaces-tests.md) |
| 6 | ACL facades (provider and consumer side) | [references/application-tests.md](references/application-tests.md#acl-facades) |

Before writing tests for any layer, check [references/mocking-and-fakes.md](references/mocking-and-fakes.md): only mock dependencies outside the package under test, prefer hand-rolled fakes, never mock `pgx` / `database/sql` / GORM.

Before shipping, check [references/coverage-ci-and-checklist.md](references/coverage-ci-and-checklist.md) for coverage expectations by layer, CI requirements, `go test` commands, common pitfalls, and the final bounded-context checklist.

The full inside-out TDD flow (domain → application → infrastructure → interfaces) is in [references/tdd-flow.md](references/tdd-flow.md).

## Source of truth

The full guide for this skill is split across the reference files linked in the build order above. There is no single combined source document in this repository.

## Related skills

- [ddd-go](../../domain-driven-design-ddd/frameworks/go-ddd/SKILL.md) — the DDD layered architecture this skill tests against.
- [data-design](../../../data-design/SKILL.md) — schema, constraints, indexing for the infrastructure tests.
- [http-api-design](../../../software-architecture/http-api-design/SKILL.md) — REST contract, status codes, Problem Details (validated by the interface tests).
