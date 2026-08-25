---
name: ddd-core
description: Model systems with Domain-Driven Design (DDD) language- and framework-agnostic — strategic design (subdomains, bounded contexts, ubiquitous language, context mapping), tactical building blocks (entities, value objects, aggregates, domain events, domain services, repository ports), Vernon's aggregate sizing rules, object lifecycle orchestration, and CQRS adoption levels. Use when designing domain models, sizing aggregates, splitting bounded contexts, or structuring context maps.
---

# DDD Core: strategic and tactical modeling

Domain-Driven Design decides **where** to invest modeling before deciding **how** to model. Strategic design separates the **problem space** (subdomains that exist whether or not you write code) from the **solution space** (bounded contexts you deliberately design); tactical design fills each context with a model that expresses business rules in code instead of shaping data for a database. This skill provides the complete language- and framework-agnostic foundation for strategic and tactical domain modeling.

## Core rules

1. Classify every subdomain as core, supporting, or generic **before** modeling anything. Spend rich tactical design only on core; buy or integrate generic.
2. Never assume a subdomain maps 1:1 to a bounded context. Make the mapping deliberate.
3. Draw context boundaries where a term changes meaning. One glossary per context, never a global canonical model.
4. Give every context relationship an explicit upstream/downstream direction and a named integration pattern. Name the owning teams too.
5. Default to an Anticorruption Layer against legacy, third-party, or low-quality upstreams. An ACL that only renames fields is worthless — translate semantics.
6. Start modeling with value objects. Every primitive carrying rules (email, money, date range) is a value object candidate; it must be immutable and self-validating.
7. Put a rule where its data lives: one aggregate's data → the aggregate; several aggregates' data → a domain service.
8. One transaction modifies exactly one aggregate instance. Reference other aggregates by identity only; propagate the rest through domain events.
9. An object never exists in an invalid state. Constructors and factories validate; state changes happen through intention-revealing methods, never setters.
10. The domain knows nothing about infrastructure — no ORM, HTTP, or framework annotations. Repository interfaces live in the domain, implementations in infrastructure, one per aggregate root.
11. Application services orchestrate, they do not decide. An `if` on a business rule inside one means the rule escaped the domain.
12. Apply CQS at method level always; adopt CQRS as an architecture only when the level below it hurts.

## Workflow

Run strategic first, then tactical — each step's output feeds the next. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Discover the domain and classify subdomains (core / supporting / generic) | [references/subdomains.md](references/subdomains.md) |
| 2 | Draw bounded contexts and fix the ubiquitous language per context | [references/bounded-contexts.md](references/bounded-contexts.md) |
| 3 | Choose the integration pattern for each context relationship and draw the context map | [references/context-mapping.md](references/context-mapping.md) |
| 4 | Model the tactical building blocks inside each context | [references/building-blocks.md](references/building-blocks.md) |
| 5 | Draw aggregate boundaries with Vernon's four rules | [references/aggregate-boundaries.md](references/aggregate-boundaries.md) |
| 6 | Wire the object lifecycle: factories, reconstitution, repository port/adapter, application service | [references/object-lifecycle.md](references/object-lifecycle.md) |
| 7 | Decide the CQRS adoption level and shape the two stacks | [references/cqrs.md](references/cqrs.md) |

## Common mistakes

- One canonical enterprise-wide model. That is the problem DDD exists to solve, not a goal.
- Boundaries drawn by technical layer (all entities together, all services together) instead of by business area.
- Full tactical DDD in a generic subdomain — paying complexity with no return.
- Conformist chosen out of laziness when the foreign model contradicts your domain; it colonizes the core.
- A Shared Kernel that grows into the company's canonical model.
- Anemic model: entities with getters and setters, all logic in services. Procedural code wearing DDD names.
- God aggregates that load half the system to change one field; unbounded collections inside an aggregate.
- Direct object references between aggregates instead of identifiers; a transaction saving two aggregate roots.
- Repositories per table instead of per aggregate root; repositories returning ORM entities, rows, or DTOs.
- Empty constructors plus setters, or a `validate()` method someone can forget to call.
- Events named in the imperative (`CreateOrder`) — that is a command; an event is `OrderCreated`.
- Queries that go through the domain repository and rehydrate aggregates just to render a list.
- Commands that return the modified aggregate, leaking the write model into presentation.
- Jumping straight to separate read/write databases "because that's CQRS"; assuming CQRS implies Event Sourcing.
