---
name: go-ddd
description: Implement or review technology-neutral DDD bounded contexts in Go with Gin confined to the HTTP boundary. Covers pure domain modeling, application use cases, context-owned persistence adapters, REST contracts, ACLs, runtime assembly, testing, and observability without mandating a database or configuration stack.
---

# DDD Bounded Contexts in Go + Gin

Use this skill to design, implement, or review a Go bounded context. Gin is an HTTP adapter, not a domain or application dependency. Persistence, configuration sources, storage engines, ORMs, migration tools, and dependency-injection frameworks are implementation choices—not DDD requirements.

The paths and identifiers below are illustrative. Replace placeholders such as `[context-name]`, `[Entity]`, and `[technology]` with the project's ubiquitous language and actual choices. Preserve established project conventions when they maintain the same boundaries; do not scaffold layers that have no real responsibility.

## Baseline

- Use an organization-approved stable Go release.
- Use `github.com/gin-gonic/gin` only at HTTP boundaries.
- Document public HTTP contracts in OpenAPI 3.1.
- Pass `context.Context` to I/O boundaries for cancellation, deadlines, and request-scoped information.
- Use `log/slog` for structured logs; add OpenTelemetry when tracing or metrics are needed.
- Use Go's standard `testing` and `net/http/httptest` packages.
- Select persistence and configuration per application/context and operational needs; no particular engine, driver, ORM, query generator, migration tool, configuration format, or DI framework is required.

## Read the relevant reference

Load the focused reference for the work at hand; do not front-load every document.

| Concern | Reference |
|---|---|
| Dependency rules, package placement, naming, shared code | [Architecture and structure](references/architecture-and-structure.md) |
| Value Objects, entities, aggregates, states, events, domain services | [Domain model](references/domain-model.md) |
| Commands, queries, command/query services | [Application layer](references/application-layer.md) |
| Domain repository ports and context-owned persistence adapters | [Persistence](references/persistence.md) |
| HTTP resources, Gin controllers, OpenAPI | [REST API](references/rest-api.md) |
| ACL, context boundaries, Shared Kernel, integration delivery | [Context integration](references/context-integration.md) |
| Runtime configuration, composition, reliability, observability | [Runtime and observability](references/runtime-and-observability.md) |
| Unit, adapter, HTTP, and cross-context tests | [Testing](references/testing.md) |
| Suggested implementation progression and final review | [Implementation workflow](references/implementation-workflow.md) |

## Default implementation progression

Discover context ownership and invariants → model and test domain behavior → define application contracts and domain repository ports → implement only required adapters → add use-case orchestration → expose HTTP contracts if needed → assemble runtime dependencies → add ACL/reliable delivery only when justified → verify behavior, operational needs, and published contracts.

Do not let this sequence override a project's existing package conventions or become a reason to introduce unnecessary layers.

## Related guidance

- [ddd-core](../../ddd-core/SKILL.md) — language-agnostic context mapping, aggregate boundaries, and domain modeling.
- [http-api-design](../../../software-architecture/http-api-design/SKILL.md) — additional HTTP contract and semantics guidance.
- [data-design](../../../data-design/SKILL.md) — apply only when relational schema design is actually selected; it does not make relational persistence mandatory here.
