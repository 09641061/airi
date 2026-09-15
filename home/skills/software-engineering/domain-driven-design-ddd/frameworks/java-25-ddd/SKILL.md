---
name: ddd-java25-spring
description: Implement a complete Domain-Driven Design (DDD) bounded context in Java 25 / Spring Boot 3.x — value objects, commands, queries, events, domain services, JPA repositories, application services, REST layer, and cross-context ACL. Use whenever asked to build, scaffold, or review a bounded context, aggregate, CQRS layer, or anti-corruption layer (ACL) in a Java/Spring codebase following DDD/hexagonal patterns.
---

# DDD Bounded Context Implementation (Java 25 + Spring Boot)

Baseline stack: Java 25 LTS, Spring Boot 3.x, Jakarta APIs, OpenAPI 3.1.

Naming principle is mandatory across the whole context: **Descriptive/Role-based Naming** or **Explicit Transformation Naming**.

For the language-agnostic modeling rules behind this skill — subdomains, bounded contexts, context mapping, building blocks, aggregate boundaries, object lifecycle, and CQRS adoption levels — see [ddd-core](../../ddd-core/SKILL.md).

## Core rules

1. **The domain layer must not import any framework or infrastructure type.** No `org.springframework.*`, no `jakarta.persistence.*`, no Hibernate, no JPA, no Jackson, no SLF4J binding, no JDBC, no PostgreSQL driver. Domain code depends only on JDK + the project's own modules. This rule has priority over any convenience you might gain by adding an annotation.
2. **No DTO classes inside the domain model.** DTOs live only at boundaries (REST, ACL, messaging).
3. **No generic mapper classes inside the domain model.** Mapping at boundaries must be explicit and minimal. Mappers themselves are infrastructure, even when the source and target are both domain types.
4. **Repository ports live in the domain; adapters live in infrastructure.** The domain declares `interface CargoRepository { ... }`; the JPA `JpaRepository` extending adapter that implements it lives in `infrastructure/persistence/jpa/repositories/`. One port per aggregate root, never per table.
5. **Every REST response is fully documented with OpenAPI/Swagger annotations** in the interfaces layer.

## Build order

Follow this order — each step's output feeds the next. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Value objects (IDs, validated primitives) — no `@Embeddable`, no JPA annotations | [references/value-objects.md](references/value-objects.md) |
| 2 | Enums | — (plain Java enums, no reference needed) |
| 3 | Commands & Queries (records) | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 4 | Domain services (pure logic interfaces, e.g. `*Policy`, `*Calculator`) | [references/domain-services.md](references/domain-services.md) |
| 4.5 | Application service contracts (`*CommandService` / `*QueryService`) and their implementations | [references/application-services.md](references/application-services.md) |
| 5 | Entities & Aggregate roots | — (use platform's shared auditable base models if available) |
| 6 | Domain events | [references/events.md](references/events.md) |
| 7 | Infrastructure repositories | [references/infrastructure-repositories.md](references/infrastructure-repositories.md) |
| 8 | Command/Query service implementations | [references/application-services.md](references/application-services.md) |
| 9 | REST resources (DTOs) & controllers | [references/rest-layer.md](references/rest-layer.md) |
| 10 | Outbox / integration events | see [references/events.md](references/events.md) |

If the context needs to talk to another bounded context, add the **ACL layer** — see [references/acl-cross-context.md](references/acl-cross-context.md). Never let contexts call each other directly.

Before shipping, check [references/testing-and-observability.md](references/testing-and-observability.md).

## Source of truth

The full guide for this skill is split across the reference files linked in the build order above. There is no single combined source document in this repository.

## Related skills

- [ddd-core](../../ddd-core/SKILL.md) — language-agnostic rules (entities, value objects, aggregates, repository ports, CQRS levels).
- [data-design](../../../data-design/SKILL.md) — physical schema, constraints, indexing, migrations; especially rule 9 ("No ORM leakage into the domain").
- [http-api-design](../../../software-architecture/http-api-design/SKILL.md) — REST contracts, status codes, RFC 7807/9457 Problem Details, pagination, optimistic concurrency.
- [java-tdb](../../test-driven-development-tdb/java-tdb/SKILL.md) — testing conventions for this skill.
