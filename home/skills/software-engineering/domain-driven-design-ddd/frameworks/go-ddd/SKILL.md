---
name: ddd-go
description: Implement a complete Domain-Driven Design (DDD) bounded context in Go — value objects, entities, aggregates, domain errors, repository ports, application services, PostgreSQL+pgx persistence, net/http interfaces, OpenAPI/Swagger, domain events, and cross-context ACL. Uses layered architecture (interfaces → application → domain ← infrastructure), standard library first, descriptive file/method naming. Use whenever asked to build, scaffold, or review a Go service or bounded context following DDD/hexagonal patterns.
---

# DDD Bounded Context Implementation (Go)

Baseline stack: Go (latest stable), standard library (`net/http`, `log/slog`, `context`, `testing`), PostgreSQL + `pgx`, plain SQL, OpenAPI 3.1.

**Naming principle is mandatory across the whole context:** Descriptive/Role-based Naming (e.g. `user_command_service.go`, `HandleCreateUser`, `HandleUpdateUser`) or Explicit Transformation Naming (e.g. `UserToUserResource`). Never use bare `Handle` together with `HandleUpdate` in the same interface — Go has no overloading, so the suffix is what disambiguates. The same rule applies to mappers, transformers, and resource types.

For the language-agnostic modeling rules behind this skill — subdomains, bounded contexts, context mapping, building blocks, aggregate boundaries, object lifecycle, and CQRS adoption levels — see [ddd-core](../../ddd-core/SKILL.md).

## Core rules

1. **The domain layer must not import any framework, transport, or infrastructure package.** No `net/http`, no `gin-gonic/gin`, no `gorm`, no `pgx`, no `database/sql`, no `encoding/json` tags as a persistence strategy, no NATS, no OpenAPI. Domain code depends only on the Go standard library and the project's own modules. This rule has priority over any convenience you might gain by adding an annotation or driver import.
2. **No DTO/resource structs inside the domain model.** Resources live only at boundaries (`interfaces/rest/resources/`). Domain entities and value objects are not transport types.
3. **No mapper packages inside the domain.** Mapping at boundaries is explicit and lives in `interfaces/...` (HTTP) or `infrastructure/...` (persistence). The domain does not import mappers.
4. **Repository ports live in the domain; adapters live in infrastructure.** The domain declares `type OrderRepository interface { ... }`; the `pgx`/`sqlx`/GORM implementation lives in `infrastructure/persistence/`. One port per aggregate root, never per table.
5. **Domain errors are typed values (`var ErrX = errors.New(...)`), never HTTP codes.** Translation to status codes happens only at the transport boundary.
6. **In Go, JSON/database tags on unexported fields are ignored by reflection.** Pick one consistent model and stick to it:
   - **Option A (preferred for value objects):** exported fields with private constructor and validation; JSON/DB tags on the exported fields. Persistence drivers work; serialization works.
   - **Option B (preferred for entities with invariants):** unexported fields with `Value()` getters, no JSON/DB tags in the domain file. Persistence uses a separate infrastructure-side model in `infrastructure/persistence/models/` with an explicit `EntityToModel` mapper. This is the only way to combine "private fields + GORM/JSON" — the critique of mixing both with no mapper is correct, and the guide picks option B for entities.
7. **Every public HTTP endpoint is fully documented with OpenAPI 3.1** in the interfaces layer (`openapi/openapi.yaml` plus per-handler doc comments).
8. **Handlers are thin.** A handler only (1) reads the request, (2) validates transport input, (3) calls the application, (4) translates typed errors to HTTP status, (5) writes the response. No business logic in handlers.

## Layer dependency rule

```
          ┌──────────────┐
          │  interfaces  │  (REST, gRPC, CLI, consumers)
          └──────┬───────┘
                 │ depends on application
                 ▼
          ┌──────────────┐
          │ application  │  (use cases, transactions, ACL)
          └──────┬───────┘
                 │ depends on domain
                 ▼
          ┌──────────────┐
          │    domain    │  (entities, VOs, aggregates, ports)
          └──────────────┘
                 ▲
                 │ implements ports
          ┌──────┴───────┐
          │infrastructure│  (pgx, NATS, external APIs)
          └──────────────┘
```

The most important rule: **domain depends on nothing outside the domain.**

## Build order

Follow this order — each step's output feeds the next. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Project structure (`internal/<context>/{domain,application,infrastructure,interfaces}`) | [references/project-structure.md](references/project-structure.md) |
| 2 | Value objects (IDs, validated primitives) — no framework tags in the domain file | [references/value-objects.md](references/value-objects.md) |
| 3 | Domain errors (`var ErrX = errors.New(...)`, typed) | [references/domain-errors.md](references/domain-errors.md) |
| 4 | Entities and aggregate roots (business methods on the type) | [references/entities-aggregates.md](references/entities-aggregates.md) |
| 5 | Domain services (pure policies/calculators) — only if business logic does not fit an entity | [references/domain-services.md](references/domain-services.md) |
| 6 | Repository ports (one per aggregate root) | [references/repositories.md](references/repositories.md) |
| 7 | Domain events (past tense, immutable) | [references/events.md](references/events.md) |
| 8 | Application services (use cases, transactions, ACL orchestration) | [references/application-services.md](references/application-services.md) |
| 9 | Optional Commands & Queries — only when they improve clarity | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 10 | Infrastructure persistence (pgx + plain SQL; add `sqlc` only when SQL surface grows) | [references/infrastructure-persistence.md](references/infrastructure-persistence.md) |
| 11 | REST resources (DTOs) and HTTP handlers (`net/http` first) | [references/rest-layer.md](references/rest-layer.md) |
| 12 | OpenAPI / Swagger UI (`openapi/openapi.yaml`, served at `/docs`) | [references/openapi-swagger.md](references/openapi-swagger.md) |
| 13 | Inter-context communication (NATS, Connect/gRPC, ACL facades) | [references/acl-cross-context.md](references/acl-cross-context.md) |

Before shipping, check [references/testing-and-observability.md](references/testing-and-observability.md) and [references/security-and-performance.md](references/security-and-performance.md).

## Source of truth

The full guide for this skill is split across the reference files linked in the build order above. There is no single combined source document in this repository.

## Related skills

- [ddd-core](../../ddd-core/SKILL.md) — language-agnostic rules (entities, value objects, aggregates, repository ports, CQRS levels).
- [data-design](../../../data-design/SKILL.md) — physical schema, constraints, indexing, migrations.
- [http-api-design](../../../software-architecture/http-api-design/SKILL.md) — REST contracts, status codes, RFC 7807/9457 Problem Details, pagination, optimistic concurrency.
- [go-tdb](../../test-driven-development-tdb/) (if present) — testing conventions for Go services.
