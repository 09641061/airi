---
name: ddd-java25-spring
description: Implement a complete Domain-Driven Design (DDD) bounded context in Java 25 / Spring Boot — value objects, entities and aggregates, application commands and queries, domain services, domain events, repository ports and persistence adapters, application use-case handlers, REST inbound adapter, and cross-context ACL. Use whenever asked to build, scaffold, or review a bounded context, use case, repository, event, or REST layer in a Java/Spring codebase following DDD patterns.
---

# DDD Bounded Context Implementation (Java 25 / Spring)

Baseline and compatibility:

- **Java 25 LTS** as the language baseline, without preview flags unless the project explicitly opts in.
- **Spring Boot**: use the version the project already supports (`3.x` or `4.x`). These rules are not a reason to upgrade or downgrade a project's Boot version.
- **Jakarta APIs** at framework boundaries; **never** in the domain.
- **OpenAPI** to document the real HTTP contract.

Naming principle is mandatory across the whole context: **Descriptive/Role-based Naming** or **Explicit Transformation Naming**.

DDD is a way to model complex business domains; it is not a mandatory set of folders, interfaces, or framework annotations. Start from the problem and add tactical patterns only when they protect real business rules or clear boundaries.

## Core rules

1. **Keep the domain framework-free.** Types in `domain/` must not import Spring, JPA/Hibernate, `jakarta.persistence`, `jakarta.validation`, HTTP, serialization, or logging. Persistence mapping and transport validation belong to their own boundaries.
2. **Commands and queries are application messages.** Place use-case inputs in `application/commands` and `application/queries` (or a consistent equivalent), not in `domain/model`.
3. **Domain services are not application services.** A domain service is a pure business policy that does not naturally belong to one entity/value object. An application service coordinates a use case: repositories, transactions, and external capabilities.
4. **Use repository ports selectively.** A domain repository port is useful in a rich model. Do not create a port per table or force a repository abstraction onto every CRUD operation. Spring Data/JPA types stay in `infrastructure`. Read-side projection ports belong to the application read layer, not to the aggregate repository.
5. **Make aggregate invariants enforceable.** Prefer intention-revealing methods and immutable value objects over public setters. Reference another aggregate by identity unless a documented local consistency requirement justifies otherwise.
6. **Keep use-case contracts in application.** An interface for inbound use cases or a module's public API belongs to `application` when it provides real decoupling. A single internal implementation does not automatically need an interface plus an `Impl`.
7. **Treat `interfaces/` as the inbound adapter.** REST controllers, request/response resources, and HTTP error translation live in `interfaces/rest` (or `adapters/inbound/rest`). `infrastructure/` holds persistence, security/framework configuration, messaging, and outbound adapters.
8. **Map only at real boundaries.** REST DTOs, application commands, domain objects, and JPA entities have different jobs. Add explicit mapping when it protects a boundary; avoid one-for-one mapper layers with no useful separation.
9. **CQS is not CQRS.** Keep command and query methods conceptually separate. Adopt separate read models or stores only when complexity, load, or query shape warrants them. Do not rehydrate full aggregates just to render a list.
10. **Integrate contexts through owned contracts.** A provider exposes a small application API; a consumer adapts it to the consumer's language. Do not import another context's private entities or persistence types. An ACL is useful when it protects the consumer from a foreign model or protocol; it is not a mandatory extra layer for every in-process call.
11. **Use events and an outbox deliberately.** Domain events are plain immutable Java types. Spring events are delivery mechanisms, not domain types. An outbox applies when integration-event delivery must survive process failure; it is not required for every event.
12. **Never encode absence or errors as sentinels.** Use `Optional` for absence and a typed result/error when callers must distinguish failure reasons. `0L`, `-1`, and `""` are not "not found".
13. **Preserve project contracts.** An architecture refactor must not silently change routes, payloads, status codes, business rules, or database schema.

### Clarifications on DTOs and mappers

- DTOs are **allowed and recommended** at boundaries (REST, ACL, messaging).
- Mapping is **allowed** at boundaries (controller/adapters/ACL) and should be explicit and minimal.
- What is prohibited is a generic DTO/mapper **inside the domain model**, and one-for-one mappers with no purpose.

### Architecture vocabulary

- **DDD** identifies the model, ubiquitous language, aggregates, subdomains, and bounded contexts. It is not a synonym for Clean Architecture.
- **Hexagonal architecture** describes ports and adapters around a core: ports are owned by the core, adapters implement them from the outside.
- **Clean Architecture** emphasizes the dependency direction toward policy; package names alone do not enforce that rule.

A **modular monolith** is usually the simplest deployment model for several bounded contexts: keep module APIs narrow and enforce dependency direction before introducing network boundaries.

## Layer map

Every location below is a guide-mandated placement for `[context-name]`.

| Layer | Package | Holds | Must never hold |
| :--- | :--- | :--- | :--- |
| Domain | `domain/model/valueobjects/` | Value objects (records, self-validating) | Framework annotations, persistence types |
| Domain | `domain/model/aggregates/` | Entities, aggregates, invariants, registered domain events | Framework annotations, repository access |
| Domain | `domain/model/events/` | Domain events (plain immutable Java types) | `ApplicationEvent`, messaging/persistence frameworks |
| Domain | `domain/services/` | Pure domain policies that fit no single entity/value object | Spring, JPA, repositories, HTTP, transactions, messaging |
| Domain | `domain/repositories/` | Repository ports, only when they provide a real aggregate boundary | Spring Data, JPA, `EntityManager`, `Pageable`, SQL, persistence entities |
| Application | `application/commands/`, `application/queries/` | Command/query records (use-case inputs) | Business rules that belong to an aggregate |
| Application | `application/` | Use-case handlers, orchestration, transactions, public module API (`application/api/`), outbound ports (`application/ports/out/`) | Aggregate invariants, persistence entities |
| Infrastructure | `infrastructure/persistence/jpa/` | JPA entities, Spring Data repositories, adapters, assemblers, embeddables | Domain decisions |
| Infrastructure | `infrastructure/acl/` | Consumer-side adapters translating another context's API | Provider domain types |
| Inbound adapter | `interfaces/rest/` (or `adapters/inbound/rest/`) | Controllers, request/response resources, HTTP error translation | Business rules, repository access |

## Build order

This is the implementation timeline of the guide. Follow it in order and load each reference only when you reach that step; don't front-load all of them. Steps 4, 5, and 8–15 are conditional: add them when the use case justifies them, not by template.

| # | Step | Reference |
|---|------|-----------|
| 1 | Value Objects — ids and domain value objects | [references/value-objects.md](references/value-objects.md) |
| 2 | Enums — statuses and domain types | — (plain Java enums, no reference needed) |
| 3 | Aggregates & Entities — invariants and behavior | [references/entities-and-aggregates.md](references/entities-and-aggregates.md) |
| 4 | Commands — intent records in `application/commands` | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 5 | Queries — read records in `application/queries` | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 6 | Domain Services — only the pure policies that need them | [references/domain-services.md](references/domain-services.md) |
| 7 | Domain Events — domain facts as plain Java types | [references/domain-events.md](references/domain-events.md) |
| 8 | Repository Ports — only where they provide a real boundary | [references/repository-ports.md](references/repository-ports.md) |
| 9 | Persistence Adapters — JPA entities, Spring Data, assembler, adapter | [references/repository-ports.md](references/repository-ports.md) |
| 10 | Application Services — orchestration and transactions | [references/application-services.md](references/application-services.md) |
| 11 | REST Resources — transport contracts | [references/rest-layer.md](references/rest-layer.md) |
| 12 | Controllers — endpoints and error translation | [references/rest-layer.md](references/rest-layer.md) |
| 13 | ACL / Context API — only when contexts collaborate | [references/acl-cross-context.md](references/acl-cross-context.md) |
| 14 | Outbox / Integration — only when delivery must be durable | [references/domain-events.md](references/domain-events.md) |
| 15 | Tests — domain first, then application, infrastructure, and HTTP contract | [references/testing-and-observability.md](references/testing-and-observability.md) |

## Anti-patterns

| Anti-pattern | Technical manifestation | Consequence | Correction |
| :--- | :--- | :--- | :--- |
| **Contaminated domain** | `@Embeddable`, `@Entity`, or Spring imports in `domain/` | The core is neither testable nor portable | Keep persistence in `infrastructure` with explicit mapping |
| **Commands/queries in the domain** | `domain/model/commands`, `domain/model/queries` | The domain carries application messages | Move them to `application/commands` and `application/queries` |
| **Repository per table** | One `Repository` per JPA entity | Ceremony and ports without a boundary | One port per aggregate root, only when it adds value |
| **One-for-one mapper** | `XAssembler` copying identical fields | Debt and noise | Map only at boundaries with a real difference |
| **Pass-through service** | `Service` → `Service` → repository | Classes with no responsibility | Merge into the service that orchestrates the use case |
| **Error sentinels** | `0L`, `-1`, `""` for "not found" | Silent errors and bugs | `Optional` or a typed result |
| **ACL contract in an outer adapter** | Provider implements an interface located in `interfaces/` | Outward dependency | Contract in the provider's application API |
| **Domain event with a framework** | Event extending `ApplicationEvent` | The domain depends on Spring | Plain Java type; delivery in infrastructure |
| **Cross-context transaction** | One `@Transactional` spans two contexts | False atomicity | Keep the transaction inside one context |
| **Optimistic mutation** | Success assumed without awaiting the result | UI/state inconsistency | Confirm the outcome before continuing |

## Delivery checklist

- [ ] Domain free of Spring, JPA, HTTP, and Jakarta
- [ ] Commands and queries in `application`
- [ ] Aggregates with enforceable invariants and no public setters
- [ ] Repository ports only where they provide a boundary
- [ ] Application orchestrates; the domain decides invariants
- [ ] `interfaces/rest` translates HTTP; `infrastructure` implements the technology
- [ ] Each context's contract lives in its own application layer
- [ ] Plain domain events; outbox only when needed
- [ ] No sentinels and no exposure of internal details
- [ ] HTTP, business, and persistence contracts preserved

## Source of truth

The full guide this skill is derived from (kept for traceability) lives at:
`software-engineering/domain-driven-design-ddd/java/java25-spring.md`.
