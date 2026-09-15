# Domain Model Unit Tests (Events, Aggregates, Entities, Domain Services)

## Domain Events. Location: `[context-name]/domain/model/events/`

Domain events represent something that already happened. Unit tests must ensure that events carry only correct and essential information.

- **Past-Tense Event Creation:** Test that the event can be created after a domain action
- **Required Data:** Test required identifiers and event fields
- **Timestamp:** Test that occurrence date/time is assigned
- **Immutability:** Event data should not be modified after creation
- **Essential Data Only:** Prefer IDs instead of full aggregate objects

Checklist:
- [ ] Event creation is tested
- [ ] Required event data is tested
- [ ] Timestamp is tested
- [ ] Event immutability is preserved
- [ ] Event does not expose unnecessary domain objects

## Aggregates. Location: `[context-name]/domain/model/aggregates/`

Aggregates contain the most important business rules. Unit tests must focus on domain behavior, not simple getters and setters.

- **Valid Creation:** Test aggregate creation with valid domain data
- **Invariant Protection:** Test rules that prevent invalid state
- **State Transitions:** Test actions such as activate, cancel, assign, approve, reject, complete, solve, close, or update
- **Invalid Transitions:** Test actions that should be blocked
- **Domain Events:** Test that events are registered when relevant
- **Encapsulation:** Test behavior through public methods, not internal fields
- **No Persistence Testing:** Do not test JPA mappings here as unit tests

Checklist:
- [ ] Aggregate valid creation is tested
- [ ] Invariants are tested
- [ ] Valid state transitions are tested
- [ ] Invalid state transitions are tested
- [ ] Domain events are tested when used
- [ ] Tests focus on behavior, not getters/setters
- [ ] No database is required

## Entities. Location: `[context-name]/domain/model/entities/`

Entities inside an aggregate should be tested when they contain meaningful behavior or rules.

- **Valid Entity Creation:** Test creation with valid values
- **Identity Rules:** Test identity-related behavior if present
- **State Changes:** Test meaningful behavior inside the entity
- **Validation Rules:** Test invalid construction or updates
- **Avoid Anemic Testing:** Do not test entities that only contain getters/setters and no logic

Checklist:
- [ ] Entity creation is tested when meaningful
- [ ] Entity behavior is tested
- [ ] Validation rules are tested
- [ ] State changes are tested
- [ ] Getter/setter-only entities are not over-tested

## Domain Services. Location: `[context-name]/domain/services/`

Domain services should be tested when they implement domain logic that does not naturally belong to a single aggregate.

- **Business Rule Focus:** Test domain calculations, policies, or validations
- **Pure Logic Preferred:** Domain service tests should avoid infrastructure
- **Multiple Inputs:** Test different business scenarios
- **Edge Cases:** Test exceptional or boundary situations
- **No Repository Dependency:** If a service needs repositories, it may be an application service, not a pure domain service

Checklist:
- [ ] Business rules are tested
- [ ] Normal scenarios are tested
- [ ] Edge cases are tested
- [ ] Invalid scenarios are tested
- [ ] No infrastructure is required
- [ ] Tests remain deterministic

> **Persistence tests are out of scope here.** JPA mappings, `@Query` methods, embeddable mappings, and database-level constraints live in [persistence-integration.md](persistence-integration.md), not in this reference. The reminder that *application service tests must mock the domain repository port* is captured in [application-services.md](application-services.md).
