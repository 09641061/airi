---
name: go-ddd
description: Implement or review Domain-Driven Design (DDD) bounded contexts in Go with Gin confined to the HTTP transport boundary. Covers cohesive domain packages, value objects, entities and aggregates, application commands and queries, consumer-side repository ports, context-owned persistence adapters with explicit mapping, the Go error model, transactions, REST contracts, ACLs, runtime assembly, testing, and observability — without mandating a database, ORM, configuration format, or DI framework.
---

# DDD Bounded Context Implementation (Go + Gin)

A step-by-step guide to implementing a bounded context with Domain-Driven Design on Go with Gin. DDD is a way to model complex business domains; it is not a mandatory set of folders, interfaces, or framework annotations. Start from the problem and add tactical patterns only when they protect real business rules or clear boundaries.

**Gin is the HTTP adapter**, not an application or domain dependency. Persistence, configuration sources, storage engines, ORMs, migration tools, and dependency-injection frameworks are implementation choices — not DDD requirements.

Naming principle remains mandatory: **Descriptive/Role-based Naming** or **Explicit Transformation Naming**. Exported Go identifiers use `PascalCase`, unexported identifiers use `camelCase`, and filenames use descriptive `snake_case.go`. Name business abstractions by role (`CourseRepository`) and technical implementations by technology (`PostgresCourseRepository`).

## Baseline and compatibility

- **Go** — stable, organization-approved release.
- **Gin** (`github.com/gin-gonic/gin`) — REST/HTTP boundary only.
- **OpenAPI 3.1** — documented HTTP contracts.
- **`context.Context`** — cancellation, deadlines, and request-scoped information at I/O boundaries.
- **`errors`** — sentinel errors and typed errors, matched with `errors.Is`/`errors.As` and wrapped with `%w`.
- **`log/slog`** — structured logs; OpenTelemetry when tracing or metrics are required.
- Go standard **`testing`** and **`net/http/httptest`** — unit and HTTP tests.
- **Persistence — selected per bounded context and operational requirements.** No database driver, connection pool, ORM, migration tool, or query generator is mandatory.
- **Configuration — implementation-defined.** The source and format of configuration are application decisions.

## Core rules

1. **Keep the domain framework-free.** Types in `domain/` must not import Gin, persistence clients, configuration libraries, HTTP packages, or logging frameworks. Persistence mapping and transport validation belong to their own boundaries.
2. **Commands and queries are application messages.** Place use-case inputs in `application/commands` and `application/queries` (or a consistent equivalent), not in `domain/`. Domain methods receive domain values and express business intent.
3. **Domain services are not application services.** A domain service is a pure business policy that does not naturally belong to one entity/value object. An application service coordinates a use case: repositories, transactions, and external capabilities.
4. **Use repository ports selectively.** A repository port is useful when an application service needs aggregate-oriented persistence behind a stable boundary. Do not create a port per table, or force a repository abstraction onto every simple CRUD operation. Go satisfies interfaces implicitly, so the port is declared by its consumer and the adapter implements it. Persistence types stay in `infrastructure`.
5. **Make aggregate invariants enforceable.** Prefer intention-revealing methods and immutable value objects over exported setters. Reference another aggregate by identity unless a documented local consistency requirement justifies otherwise.
6. **Keep use-case contracts in application.** An interface for inbound use cases or a module's public API belongs to the application boundary when it provides real decoupling. A single internal implementation does not automatically need an interface and an implementation pair.
7. **Treat the transport layer as the inbound adapter.** HTTP handlers, request/response resources, and HTTP error translation live in `transport/http/` (or `api/http/`). Infrastructure holds persistence, security/framework configuration, messaging, and outbound adapters.
8. **Map only at real boundaries.** HTTP DTOs, application contracts, domain objects, and persistence rows have different jobs. Add explicit mapping when it protects a boundary; avoid one-for-one mapper layers with no useful separation.
9. **CQS is not CQRS.** Keep command and query methods conceptually separate. Adopt separate read models or stores only when complexity, load, or query shape warrants them. Do not rehydrate full aggregates just to render a list.
10. **Integrate contexts through owned contracts.** A provider exposes a small application API; a consumer adapts it to the consumer's language. Do not import another context's private entities or persistence types. An ACL is useful when translation or protection is needed, not a mandatory extra layer for every in-process call.
11. **Use events and an outbox deliberately.** Domain events are plain immutable Go types. An outbox applies when an integration event must survive process failure; it is not required for every event and only makes sense when the storage engine supports it.
12. **Never encode absence or errors as sentinels.** Use a sentinel error for absence (`ErrCourseNotFound`) and typed errors when callers must distinguish failure reasons. `0` and `""` are not "not found".
13. **Preserve project contracts.** Architecture refactors must not silently change routes, payloads, status codes, business rules, or database schema. Treat any such change as a separate, explicit decision.
14. **Keep `context.Context` disciplined.** It is the first parameter of any function that performs I/O, it is never stored in a struct, and it is never `nil`. Propagate it to every downstream I/O call so cancellation and deadlines reach the adapter.
15. **Keep packages cohesive.** A Go package is the unit of cohesion and encapsulation, not a folder that mirrors a file type. Keep an aggregate with its value objects, states, events, and invariants in one package; split only when a real boundary requires it.

### Clarifications on DTOs and mappers

- DTOs are **allowed and recommended** at boundaries (REST, ACL, messaging).
- Mapping is **allowed** at boundaries (controller/adapters/ACL) and should be explicit and minimal.
- What is prohibited is a generic DTO/mapper **inside the domain model**, and one-for-one mappers with no purpose.

## Architecture vocabulary

- **DDD** identifies the model, ubiquitous language, aggregates, subdomains, and bounded contexts. It is not a synonym for Clean Architecture.
- **Hexagonal architecture** describes ports and adapters around a core; ports are owned by the core, adapters implement them from the outside.
- **Clean Architecture** emphasizes the dependency direction toward policy; package names alone do not enforce that rule.

A **modular monolith** is usually the simplest deployment model for several bounded contexts: keep module APIs narrow and enforce dependency direction before introducing network boundaries.

## Layer map

| Layer | Package | Holds | Must never hold |
| :--- | :--- | :--- | :--- |
| Domain | `[context-name]/domain/` | Cohesive package per aggregate: value objects, entities, states, invariants, domain events, domain policies | Gin, persistence, configuration, transport, other contexts' private types |
| Application | `[context-name]/application/` | Command/query contracts, use-case handlers, consumer-side ports, public in-process contract for other contexts | Aggregate invariants, engine transaction handles, `*gin.Context` |
| Infrastructure | `[context-name]/infrastructure/` | Persistence adapters, row types, mapping functions, clients, external integrations | Business rules, transport concerns |
| Transport | `[context-name]/transport/http/` | Gin handlers, request/response resources, HTTP error translation | Business rules, persistence access, cross-context orchestration |
| Shared technical | `internal/shared/infrastructure/` | Configuration loader, telemetry setup, HTTP middleware, client factory | Business rules, context-owned repositories |

`internal/` is Go's visibility mechanism: packages under it are importable only inside the subtree that contains them. Avoid a top-level `pkg/` unless the module publishes a reusable library.

## Build order

Follow this order and load each reference only when you reach that step. Steps 8–19 are conditional: add them when the use case justifies them, not by template.

| # | Step | Reference |
|---|------|-----------|
| 1 | Value Objects — define and test validated domain values | [references/domain-model.md](references/domain-model.md) |
| 2 | Enums/States — express valid domain states and transitions | [references/domain-model.md](references/domain-model.md) |
| 3 | Entities and Aggregates — model identity, behavior, lifecycle, and invariants | [references/domain-model.md](references/domain-model.md) |
| 4 | Commands — define state-changing application intentions | [references/application-layer.md](references/application-layer.md) |
| 5 | Queries — define read-use-case contracts | [references/application-layer.md](references/application-layer.md) |
| 6 | Domain Services — introduce only justified business policies | [references/domain-model.md](references/domain-model.md) |
| 7 | Domain Events — represent meaningful completed facts when needed | [references/domain-model.md](references/domain-model.md) |
| 8 | Error Model — define the sentinel and typed errors the domain and application return | [references/errors.md](references/errors.md) |
| 9 | Ports — define the consumer-side repository interfaces each use case needs | [references/persistence.md](references/persistence.md) |
| 10 | Infrastructure Adapters — implement ports under `persistence/[technology]/` | [references/persistence.md](references/persistence.md) |
| 11 | Transactions / Unit of Work — only when the use case needs atomicity the engine supports | [references/persistence.md](references/persistence.md) |
| 12 | Command Services — orchestrate domain mutations and consistency | [references/application-layer.md](references/application-layer.md) |
| 13 | Query Services — implement bounded reads/projections | [references/application-layer.md](references/application-layer.md) |
| 14 | REST Resources — define HTTP contracts | [references/rest-api.md](references/rest-api.md) |
| 15 | Gin Controllers — implement HTTP adapters | [references/rest-api.md](references/rest-api.md) |
| 16 | Composition Root — wire components in `cmd/api/main.go` or `internal/bootstrap/` if complexity warrants it | [references/runtime-and-observability.md](references/runtime-and-observability.md) |
| 17 | ACL and integration — connect bounded contexts through explicit contracts | [references/context-integration.md](references/context-integration.md) |
| 18 | Outbox/coordination — add only when delivery must be durable and the storage engine supports it | [references/domain-model.md](references/domain-model.md) |
| 19 | Testing and observability — verify business rules, storage contracts, API contracts, and operational behavior | [references/testing.md](references/testing.md), [references/runtime-and-observability.md](references/runtime-and-observability.md) |

Package placement, naming, and dependency rules: [references/architecture-and-structure.md](references/architecture-and-structure.md).

## Delivery checklist

- [ ] `domain/` is pure business code, free of Gin, persistence, configuration, and transport concerns.
- [ ] Ports are declared by their consumer and sized to what that consumer needs; adapters live in the owning context's `infrastructure/`.
- [ ] No persistence technology leaks through domain types or ports.
- [ ] The persistence representation and its mapping live inside the adapter.
- [ ] Persistence package names reflect the actual technology where appropriate.
- [ ] The domain model is organized as cohesive packages, not one package per file type.
- [ ] Business failures are sentinel or typed errors, matched with `errors.Is`/`errors.As`.
- [ ] `context.Context` is the first parameter of I/O functions and is never stored in a struct.
- [ ] No engine transaction type appears in application or domain code.
- [ ] Shared technical building blocks live in `shared/infrastructure`, not in a presumed DDD Shared Kernel.
- [ ] Shared Kernel domain code exists **only** after an explicit context-mapping decision and shared ownership agreement.
- [ ] Application services depend on contracts, not Gin or database drivers.
- [ ] HTTP DTOs and handlers stay at the transport boundary.
- [ ] ACL integration preserves each context's model and lives outside the transport layer.
- [ ] Plain domain events; outbox only when delivery must be durable.
- [ ] Configuration and database implementation choices remain optional and independent of DDD.
- [ ] Business rules and infrastructure contracts have meaningful tests.

## Source of truth

The full guide this skill is derived from (kept for traceability) lives at:
`software-engineering/domain-driven-design-ddd/go/go-gin-ddd.md`.

Go testing depth (fixtures, fakes, integration setup, quality gates) is covered by the Go testing skill: [go-tdb](../../../test-driven-development-tdb/go-tdb/SKILL.md).
