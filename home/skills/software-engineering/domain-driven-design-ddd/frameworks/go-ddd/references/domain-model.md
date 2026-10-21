# Domain Model

Keep business meaning and invariants in the domain. Model only concepts, rules, and consistency boundaries that the bounded context actually owns. Domain code remains independent of Gin, HTTP, configuration, persistence technologies, and other contexts' private models.

## Value Objects

Suggested location: `[context-name]/domain/model/valueobjects/`.

Value Objects represent cohesive domain concepts by value and preserve their invariants.

- Use concrete Go types or structs; hide state when needed to prevent invalid construction.
- Validate meaningful business constraints during construction and return explicit errors.
- Prefer operations that return new values over mutation; defensively copy mutable members such as slices and maps.
- Define equality, normalization, representation, and boundary behavior according to business semantics.
- Consider zero-value and decoding paths so they cannot silently bypass invariants.
- Never add database-specific tags or framework dependencies for persistence convenience.

**Review:** all construction paths preserve invariants; mutable state does not escape accidentally; equality/normalization are intentional; no SQL, ORM, document, or HTTP coupling is present.

## Entities, states, and aggregates

- Give entities identity and lifecycle behavior only when the domain requires them; keep behavior with the object that owns the rule.
- Represent allowed states and transitions explicitly. Reject invalid transitions through domain behavior rather than relying only on transport validation.
- Choose aggregate boundaries around invariants that must hold consistently. Enforce those invariants inside the aggregate; keep aggregate roots responsible for external changes to the aggregate.
- Do not derive aggregates from tables or create entity/aggregate scaffolding just to fill a layered tree.
- Coordinate persistence and any required transaction at the application/infrastructure boundary, taking the selected store's actual consistency guarantees into account.

The specific entities, invariants, and aggregate boundaries must come from the domain; placeholders in examples are not requirements.

## Domain Events

Suggested location: `[context-name]/domain/model/events/`.

Domain Events describe significant business facts that have already occurred.

- Name them as past-tense facts and use an `_event.go` filename.
- Include only information needed to describe the fact; identifiers are usually preferable to large object graphs.
- Make payloads immutable or safely copied. Include event identity and occurrence time when required; obtain time from a controlled source for deterministic tests.
- Record/emit success events only after the corresponding domain transition succeeds. A rejected transition must not report a successful fact.
- A Domain Event is not automatically an Integration Event. Cross-context translation and delivery need an explicit contract and reliability policy.

## Domain Services

Suggested location: `[context-name]/domain/services/`.

A Domain Service expresses a business policy or calculation that does not naturally belong to one Entity or Value Object. It is not an application Command Service or Query Service.

- Put state and behavior in an Aggregate when that aggregate owns the invariant.
- Introduce a domain service only for a cross-object policy or calculation with no natural entity home.
- Prefer stateless services and real domain types in their APIs.
- Add a dependency interface only when the policy genuinely requires an external capability; keep its adapter outside the domain.
- Unit-test rules with real domain objects.

## Domain checklist

- Domain rules, valid transitions, and aggregate invariants live in domain objects/services.
- Value equality and mutable state handling are explicit where relevant.
- Rejected operations leave state unchanged and do not create successful events.
- Domain types contain no transport DTOs or persistence annotations.
- Do not invent business requirements to justify an abstraction.
