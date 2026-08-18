# Domain Model Tests (Value Objects, Entities, Aggregates, Domain Services, Events)

Location: `contexts/[context]/domain/`

Value objects, entities, aggregates, and domain services protect business rules and should be tested without Next.js or infrastructure.

Test:

- Valid and invalid value object creation
- Null, blank, malformed, and boundary values
- Entity identity and meaningful state changes
- Aggregate invariants and valid or invalid transitions
- Domain events when they are emitted
- Pure domain service policies, calculations, and edge cases

Use real domain objects. Do not mock value objects, entities, or aggregates unless there is a strong technical reason.

Do not test simple getters, setters, or framework decorators without behavior.
