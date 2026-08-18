---
name: ddd-java25-spring
description: Implement a complete Domain-Driven Design (DDD) bounded context in Java 25 / Spring Boot 3.x — value objects, commands, queries, events, domain services, JPA repositories, application services, REST layer, and cross-context ACL. Use whenever asked to build, scaffold, or review a bounded context, aggregate, CQRS layer, or anti-corruption layer (ACL) in a Java/Spring codebase following DDD/hexagonal patterns.
---

# DDD Bounded Context Implementation (Java 25 + Spring Boot)

Baseline stack: Java 25 LTS, Spring Boot 3.x, Jakarta APIs, OpenAPI 3.1.

Naming principle is mandatory across the whole context: **Descriptive/Role-based Naming** or **Explicit Transformation Naming**.

## Core rules

1. No DTO classes **inside the domain model**. DTOs live only at boundaries (REST, ACL, messaging).
2. No generic mapper classes **inside the domain model**. Mapping at boundaries must be explicit and minimal.
3. Every REST response is fully documented with OpenAPI/Swagger annotations.

## Build order

Follow this order — each step's output feeds the next. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Value objects (IDs, embeddables) | [references/value-objects.md](references/value-objects.md) |
| 2 | Enums | — (plain Java enums, no reference needed) |
| 3 | Commands & Queries (records) | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 4 | Domain services (interfaces) | [references/domain-services.md](references/domain-services.md) |
| 5 | Entities & Aggregate roots | — (use platform's shared auditable base models if available) |
| 6 | Domain events | [references/events.md](references/events.md) |
| 7 | Infrastructure repositories | [references/infrastructure-repositories.md](references/infrastructure-repositories.md) |
| 8 | Command/Query service implementations | [references/application-services.md](references/application-services.md) |
| 9 | REST resources (DTOs) & controllers | [references/rest-layer.md](references/rest-layer.md) |
| 10 | Outbox / integration events | see [references/events.md](references/events.md) |

If the context needs to talk to another bounded context, add the **ACL layer** — see [references/acl-cross-context.md](references/acl-cross-context.md). Never let contexts call each other directly.

Before shipping, check [references/testing-and-observability.md](references/testing-and-observability.md).

## Source of truth

The original, unsplit guide (kept for traceability) lives at:
`software-engineering/domain-driven-design-ddd/java/java25-spring.md`.
