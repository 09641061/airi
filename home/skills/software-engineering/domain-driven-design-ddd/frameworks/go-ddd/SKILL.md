---
name: go-ddd
description: Apply DDD to a Go service with Gin. Discover the bounded context and invariants first; put aggregate state transitions on the aggregate root; keep the domain free of Gin, SQL, JSON, and persistence annotations; orchestrate use cases in application services; implement repository ports in infrastructure. Avoid layers and patterns created only to satisfy a template. Use when designing, scaffolding, or reviewing a Go bounded context that follows DDD with Gin.
---

# DDD in Go with Gin

A practical guide to modeling real business rules and keeping Gin, persistence, and external systems at the edges. Apply DDD where the business has meaningful rules; avoid layers and patterns created only to satisfy a template.

For language-agnostic modeling rules (entities, value objects, aggregates, repository ports, CQRS levels), see [ddd-core](../../ddd-core/SKILL.md).

## Core rules

1. **Discover first.** Identify the bounded context, its ubiquitous language, and its invariants before choosing patterns.
2. **Aggregate owns its invariants.** State transitions and business rules live on the aggregate root. Reference other aggregates by ID, never by embedding.
3. **Value objects for meaning, not every primitive.** Build immutable value objects for identifiers and concepts that need normalization or validation.
4. **Keep the domain clean.** No Gin, no ORM, no SQL, no JSON or persistence tags inside the domain package.
5. **Application services orchestrate.** They wire ports, load/save aggregates, wrap infrastructure errors. Business decisions belong to the domain.
6. **Optional patterns, on demand.** CQRS, events, domain services, ACLs are added only when a concrete use case justifies them — never by template.
7. **One repository port per aggregate.** Declared in the domain, implemented in infrastructure. External-system ports live near the application use case that consumes them.
8. **Explicit boundary mapping.** Map only when contracts genuinely differ. Skip generic mapper frameworks and needless copies.
9. **Local transactions, optimistic concurrency.** Keep transactions inside one aggregate. Use constraints and a versioned `Save` for concurrent writes.

## Layered structure

```text
internal/orders/
  domain/                       # aggregate, value objects, repository port, domain errors
  application/                  # use cases and external-system ports
  infrastructure/persistence/   # database-specific adapters and persistence mapping
  interfaces/httpapi/           # Gin handlers and API resources
cmd/api/                        # dependency wiring
```

The domain imports no outer layer. Application depends on domain; infrastructure implements the domain repository port. Gin is used only by the HTTP adapter.

## Build order

Follow this order — each step builds on the previous one. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Domain model: value objects, aggregate, domain errors | [references/domain-model.md](references/domain-model.md) |
| 2 | Repository port and application use cases | [references/repository-port-and-use-cases.md](references/repository-port-and-use-cases.md) |
| 3 | Persistence adapters and optimistic concurrency | [references/persistence-and-concurrency.md](references/persistence-and-concurrency.md) |
| 4 | Gin adapter and dependency wiring | [references/gin-adapter.md](references/gin-adapter.md) |
| 5 | Optional patterns (CQRS, events, ACLs, outbox/saga) | [references/optional-patterns.md](references/optional-patterns.md) |
| 6 | Test layers and pre-release checklist | [references/testing-and-delivery.md](references/testing-and-delivery.md) |

## Workflow

`discover the context and invariants → model/test the aggregate → add the use cases and ports you actually need → wire adapters in cmd/api → add CQRS, events, ACLs, or distributed coordination only when justified.`

## Related skills

- [ddd-core](../../ddd-core/SKILL.md) — language-agnostic rules (entities, value objects, aggregates, repository ports, CQRS levels).
- [go-tdb](../../../../test-driven-development-tdb/go-tdb/SKILL.md) — testing conventions for Go services (domain/app/repo/http test layers, fakes vs. mocks).
- [data-design](../../../data-design/SKILL.md) — physical schema, constraints, indexing, migrations.
- [http-api-design](../../../software-architecture/http-api-design/SKILL.md) — REST contracts, status codes, RFC 7807/9457 Problem Details, pagination, optimistic concurrency.