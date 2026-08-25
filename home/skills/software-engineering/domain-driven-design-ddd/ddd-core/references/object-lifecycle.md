# Step 6 — Object lifecycle, repository port/adapter, and application services

A domain object passes through four moments: **creation**, **reconstitution** from storage, **in-memory state transitions**, and **removal**. At every one the same promise must hold: the object never exists in an invalid state. The repository is the piece that keeps persistence from breaking that promise.

## The four stages

### 1. Creation (constructor / factory)
- The object begins life in a 100% consistent state; a unique domain identifier is assigned (`TrackingId`, `OrderId`).
- The constructor validates and guarantees the initial state. When construction is complex or rule-dependent, it goes in a **factory**.
- If the arguments are invalid, creation aborts with a domain exception. There is no `validate()` method anyone can forget to call.

### 2. Active mutation (domain rules and business methods)
- The aggregate fully encapsulates its internal state; child entities are never modified from outside.
- Changes are requested through semantically named methods (`assignRoute(itinerary)`, `confirm()`, `cancel()`), not setters.
- Each method checks the invariants before applying the change and fails explicitly when they do not hold.
- Pure domain rules recompute value objects and may record domain events.

### 3. Persistence and reconstitution (repository)
- **Persistence** — at the end of a transaction the complete aggregate is handed to the repository and saved atomically.
- **Reconstitution** — the repository loads the stored data and rebuilds the aggregate in memory; it does not "fill it in". Reconstitution assumes the stored state was already valid, so it does not re-run creation validation and does not replay past business events. A record persisted validly under old rules must not become unrecoverable when the rules change.

### 4. Removal / end of life
- Almost always logical rather than physical: the business rarely wants to forget. Model it as another state transition with its own rule (`cancel()`, `archive()`).

## Strongly typed identifiers

Use value-object identifiers (`TrackingId`, not `string`) to avoid primitive obsession and argument mix-ups in constructors and repository calls.

## Repository: port and adapter

- The repository **interface** lives in the domain layer and speaks the ubiquitous language (`findByOrderNumber`), not SQL.
- The **implementation** lives in infrastructure and knows the ORM, the table, and the driver.
- **One repository per aggregate root**, never one per table and never for a child entity (`LegRepository` is wrong — legs are loaded and saved through their root).
- It receives and returns whole, valid aggregates — never rows, ORM entities, or DTOs.
- Collection semantics only: `save`, `findById`, `delete`, `nextId`. Never expose infrastructure abstractions such as `IQueryable`, Hibernate `Criteria`, or presentation-shaped filters (`findForUIDropdown()`).

This separation is what lets the domain import nothing from persistence, and it is the precondition for testing the model without a database.

### Port (domain layer)

```typescript
// domain/model/cargo/cargo-repository.ts
import { TrackingId } from './tracking-id';
import { Cargo } from './cargo';

export interface CargoRepository {
  save(cargo: Cargo): Promise<void>;
  findByTrackingId(trackingId: TrackingId): Promise<Cargo | null>;
  nextTrackingId(): TrackingId;
}
```

### Adapter (infrastructure layer)

```typescript
// infrastructure/persistence/typeorm-cargo-repository.ts
export class TypeOrmCargoRepository implements CargoRepository {
  constructor(private readonly entityManager: EntityManager) {}

  public async save(cargo: Cargo): Promise<void> {
    await this.entityManager.save(CargoTypeOrmEntity, CargoMapper.toOrm(cargo));
  }

  public async findByTrackingId(trackingId: TrackingId): Promise<Cargo | null> {
    const row = await this.entityManager.findOne(CargoTypeOrmEntity, {
      where: { trackingId: trackingId.value },
      relations: ['legs', 'deliveryHistory'],
    });
    return row ? CargoMapper.toDomain(row) : null;
  }

  public nextTrackingId(): TrackingId {
    return TrackingId.generate();
  }
}
```

The mapper belongs to infrastructure, never to the domain. `CargoMapper.toDomain` calls the aggregate's `reconstitute` path, not its `create` factory.

## Application service

The application service **orchestrates, it does not decide**: it opens the transaction, loads the aggregate through the repository, invokes the domain method, saves, and publishes the resulting events.

- **Allowed**: transaction handling, repository coordination, invoking aggregate methods, calling infrastructure services (notifications, messaging), DTO mapping, application-level security.
- **Forbidden**: business validation rules, tariff/state calculations, mutating entity properties without going through aggregate methods.

The moment it contains an `if` on a business rule, that rule has escaped the domain — push it back into the aggregate or a domain service.

```typescript
// application/commands/route-cargo.service.ts
export class RouteCargoApplicationService {
  constructor(private readonly cargoRepository: CargoRepository) {}

  public async execute(command: RouteCargoCommand): Promise<void> {
    const trackingId = new TrackingId(command.trackingId);
    const cargo = await this.cargoRepository.findByTrackingId(trackingId);
    if (!cargo) {
      throw new CargoNotFoundError(command.trackingId);
    }

    const itinerary = Itinerary.create(command.legs.map(toDomainLeg));

    cargo.assignRoute(itinerary);          // all business logic lives here

    await this.cargoRepository.save(cargo); // atomic persistence
  }
}
```

## Hexagonal / clean architecture fit

Repository interfaces are **outbound ports** in the domain core; their ORM/SQL implementations are **infrastructure adapters**. The aggregate sits in the innermost circle (enterprise business rules), application services / command handlers in application business rules, repositories and query handlers in frameworks & drivers.

## Anti-patterns

| Anti-pattern | Problem | Fix |
| :--- | :--- | :--- |
| **Fat application service** | The service contains `if/else` validations, calculations, or direct field updates. | Move all rules and invariant validation into the aggregate root or a domain service. |
| **Repository per table / per child entity** | A repository for entities that live inside an aggregate. | Only aggregate roots get repositories; children are loaded and saved through the root. |
| **Infrastructure leaking into the port** | Repository interfaces returning `IQueryable`, ORM criteria, or infrastructure pagination types. | Domain ports return closed in-memory collections or aggregate instances. |
| **Anemic entities** | Public getters and setters with no semantic business methods. | Encapsulate state, make setters private, expose ubiquitous-language operations. |
| **Half-built objects** | Empty constructor plus setters, validated later. | Validate in the constructor or factory; make invalid state unrepresentable. |
| **Validation in the controller** | Business rules checked at the HTTP boundary. | Boundary validation handles shape and format only; business rules belong to the model. |

## Good practices

1. Treat command DTOs and value objects as immutable to prevent accidental cross-layer side effects.
2. Prefer semantic methods (`cancelOrder()`, `changeDestination()`, `recalculateDelivery()`) over generic `update()`.
3. Keep zero business logic in repositories — they translate between storage structures and domain objects, nothing more.
4. Automate domain unit tests: aggregate and value-object tests must not depend on database mocks or web frameworks and should run in milliseconds.

## Checklist

- [ ] All modifications to secondary entities go exclusively through aggregate-root methods.
- [ ] Entity setters are private/protected and collection access is read-only or immutable.
- [ ] Aggregates are created in a fully valid state through static factory methods or dedicated factories.
- [ ] Reconstitution does not re-run creation-time validation or replay past events.
- [ ] Repository interfaces live in the domain layer with no infrastructure or ORM types.
- [ ] Application services contain no business rules.
- [ ] Removal is modelled as a domain state transition wherever the business does not truly forget.
