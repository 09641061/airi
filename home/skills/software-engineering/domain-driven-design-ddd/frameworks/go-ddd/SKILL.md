---
name: go-ddd
description: Implement a complete Domain-Driven Design (DDD) bounded context in Go with Gin, PostgreSQL, Koanf, and OpenAPI. Use this skill to design, scaffold, implement, or review Go bounded contexts with clean domain boundaries, repository ports, application services, REST adapters, ACLs, testing, and observability.
---

# DDD Bounded Context Implementation Guide — Go + Gin

This skill defines a generic standard for implementing a DDD bounded context in **Go with Gin**, following the same 14-section implementation order as the Java/Spring guide. Replace `[context-name]`, `[context-a]`, `[context-b]`, `[Entity]`, and `[Field]` with project-specific names.

Use the reference files for the detailed rules, checklists, examples, and configuration snippets. Go snippets use neutral identifiers such as `Entity` and `Field`; update module imports and types for the target module.

## Baseline stack

- Go (stable, organization-approved version)
- Gin (`github.com/gin-gonic/gin`) for HTTP
- PostgreSQL with `pgx/v5/pgxpool`
- `sqlc` (optional) for typed SQL and `goose` for migrations
- Koanf v2 with YAML for configuration
- OpenAPI 3.1 for API documentation
- `log/slog` and OpenTelemetry for observability
- `testing` and `httptest` for tests

## Naming principle

Use **Descriptive/Role-based Naming** or **Explicit Transformation Naming**. Exported Go types use `PascalCase`, methods use `PascalCase` or `camelCase`, and files use `snake_case.go`.

For language-agnostic modeling rules — subdomains, bounded contexts, context mapping, building blocks, aggregate boundaries, object lifecycle, and CQRS adoption levels — see [ddd-core](../../ddd-core/SKILL.md).

## Core rules

1. **No DTOs in the domain model.** DTOs belong to REST, messaging, or ACL boundaries.
2. **No generic mapper packages in the domain model.** Convert types explicitly at boundaries.
3. **Fully document HTTP responses in OpenAPI**, including success and error cases.
4. **Repository interfaces belong to `[context-name]/domain/repositories/`; PostgreSQL implementations belong to infrastructure.**
5. `domain/` must not import Gin, SQL drivers, Koanf, or infrastructure packages.
6. `application/` depends on domain repository interfaces, never concrete PostgreSQL implementations, and receives `context.Context`, not `*gin.Context`.
7. Use constructor injection; Go does not require Spring annotations.
8. Keep bounded contexts isolated. Share only contracts expressly designed for integration.
9. Keep these paths relative to `internal/` at the Go-module root unless noted otherwise.

## Layered structure

```text
internal/[context-name]/
  domain/                       # aggregates, value objects, commands, queries, events, ports
  application/                  # command/query services and outbound ports
  infrastructure/persistence/   # PostgreSQL adapters and persistence mapping
  interfaces/rest/              # Gin controllers and request/response resources
internal/platform/              # configuration, database pool, observability
internal/bootstrap/             # dependency wiring and route registration
cmd/api/                        # process entry point and graceful shutdown
```

The domain imports no outer layer. Application services depend on domain ports; infrastructure implements those ports. Gin remains in the REST adapter. `bootstrap` is the composition root that connects interfaces to infrastructure.

## Build order and references

Follow this order. Load the matching reference when reaching each step instead of front-loading every file.

| # | Step | Reference |
|---|------|-----------|
| 1 | Value Objects — IDs and validated values | [references/value-objects.md](references/value-objects.md) |
| 2 | Commands — state-changing intentions | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 3 | Queries — validated information requests | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 4 | Events — immutable facts that already happened | [references/events.md](references/events.md) |
| 5 | Domain Services — business rules outside entities/value objects | [references/domain-services.md](references/domain-services.md) |
| 6 | Infrastructure Repositories — domain ports and PostgreSQL adapters | [references/infrastructure-repositories.md](references/infrastructure-repositories.md) |
| 7 | Command Services — write orchestration | [references/application-services.md](references/application-services.md) |
| 8 | Query Services — bounded read orchestration | [references/application-services.md](references/application-services.md) |
| 9 | REST Resources — request/response DTOs | [references/rest-layer.md](references/rest-layer.md) |
| 10 | REST Controllers — Gin HTTP adapters | [references/rest-layer.md](references/rest-layer.md) |
| 11 | Implementation timeline — entities, aggregates, transformers, outbox | [references/implementation-timeline.md](references/implementation-timeline.md) |
| 12 | ACL — cross-context contracts and translation | [references/acl-cross-context.md](references/acl-cross-context.md) |
| 13 | Testing requirements | [references/testing-and-observability.md](references/testing-and-observability.md) |
| 14 | Observability and reliability | [references/testing-and-observability.md](references/testing-and-observability.md) |

## Configuration and runtime

Use [references/configuration.md](references/configuration.md) for the Koanf/YAML configuration contract, environment overrides, PostgreSQL pool initialization, Gin bootstrap, HTTP timeouts, and graceful shutdown.

The production composition sequence is:

1. Load and validate typed configuration.
2. Set Gin mode.
3. Open and verify one PostgreSQL pool.
4. Create the Gin router with recovery and required middleware.
5. Let `bootstrap` construct infrastructure adapters and inject them through domain interfaces.
6. Register routes and start an `http.Server` with configured timeouts.
7. Handle SIGINT/SIGTERM with graceful shutdown and close the pool.

## Workflow

`discover the bounded context and invariants → model and test value objects/entities/aggregates → define domain ports → implement infrastructure adapters → add command/query services → expose REST contracts → wire dependencies → add ACL, events, outbox, and distributed coordination only when justified → verify testing and observability checklists.`

## Related skills

- [ddd-core](../../ddd-core/SKILL.md) — language-agnostic DDD rules and aggregate modeling.
- [data-design](../../../data-design/SKILL.md) — relational schemas, constraints, indexes, and migrations.
- [http-api-design](../../../software-architecture/http-api-design/SKILL.md) — HTTP semantics, errors, pagination, concurrency, and OpenAPI contracts.
