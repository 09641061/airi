---
name: java-tdb
description: Write unit tests for a Domain-Driven Design bounded context in Java/Spring Boot — value objects, enums, commands, queries, aggregates, entities, domain/application services, ACL, controllers, resources, transformers. Use whenever asked to write, review, or scaffold unit tests (JUnit 5/Mockito/AssertJ) for a Java Spring codebase following DDD/hexagonal patterns.
---

# Java/Spring Bounded Context Unit Testing

Recommended stack: JUnit 5, Mockito, AssertJ, JaCoCo, Maven, Spring Security Test.

Unit tests must be **fast, isolated, repeatable, automated**, and **independent from database, external APIs, Kafka, Redis, or real infrastructure**.

## Core conventions (apply to every layer)

- **Test structure mirrors production packages** under `src/test/java/[base-package]/[context-name]/`. One test class per production class, files end with `Test`, no shared state, no infrastructure dependency (no real DB/servers/queues unless testing the web layer).
- **Naming:** `should[ExpectedBehavior]When[Condition]` — e.g. `shouldThrowExceptionWhenEmailIsBlank`. Never use generic names like `test1` or `validateTest`; the name should read as documentation of the business rule.
- **Organization:** every test follows **Arrange / Act / Assert** — one behavior per test, one method call under Act, no unrelated assertions.

## Build order

Follow this order — each step builds on the previous one. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Value objects & enums | [references/value-objects-and-enums.md](references/value-objects-and-enums.md) |
| 2 | Commands & queries | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 3 | Domain events, aggregates, entities, domain services, repository policy | [references/domain-model.md](references/domain-model.md) |
| 4 | Application command/query services & ACL services | [references/application-services.md](references/application-services.md) |
| 5 | REST controllers, resources, transformers, error handling | [references/rest-layer.md](references/rest-layer.md) |

Before writing tests for any layer, check [references/mocking-and-test-data.md](references/mocking-and-test-data.md): only mock dependencies outside the class under test — never mock value objects, aggregates, or the class under test itself.

Before shipping, check [references/coverage-ci-and-checklist.md](references/coverage-ci-and-checklist.md) for coverage expectations by layer, CI requirements, Maven test commands, common pitfalls, and the final bounded-context checklist.

## Source of truth

The original, unsplit guide (kept for traceability) lives at:
`software-engineering/test-driven-development-tdb/java/java-spring-unit-test.md`.
