# Step 7 — CQRS: command stack and query stack

CQRS separates the model that **writes** from the model that **reads**. The justification is not aesthetic: the write model exists to protect invariants, the read model to answer queries fast. Optimizing one structure for both goals produces a model that does both badly.

## CQS is not CQRS

- **CQS (Bertrand Meyer)** — a class/method-level principle: a method either mutates state and returns `void` (command) or returns a value without altering observable state (query). Applies always, in any code, for free.
- **CQRS (Greg Young)** — an architectural pattern that lifts CQS to the subsystem level, forking object models, execution pipelines, and persistence into a command stack and a query stack. Applies only when the problem justifies it.

Confusing them leads teams to adopt the whole architecture when method-level discipline was enough.

## The two stacks

**Command stack — protects invariants.**
A command is a DTO carrying business intent, named in the imperative (`ConfirmOrder`, `ChangeDeliveryDestination`) — not a generic CRUD patch (`UpdateCargo`). Its handler loads the aggregate through the repository, invokes the domain method, persists, and publishes the domain events. The command **returns no business data** — at most the identifier of what was created. All rule validation happens inside the model.

Flow: `command controller → application service → repository.findById → aggregate business method (validates invariants, recomputes value objects, records events) → repository.save → transaction commit`.

**Query stack — answers fast.**
A query **does not go through the aggregate or the domain repository**. It reads directly from a projection optimized for the screen that needs it and returns flat DTOs. There is no business logic in this stack, and that is precisely why it may skip the model without guilt: there is no invariant to protect in a read.

Flow: `query controller → query service → SELECT against a denormalized view or read store → flat read DTO`.

## Component roles

| Component | Layer | Role | Constraints |
| :--- | :--- | :--- | :--- |
| **Command DTO** | Application / ports | Represents an intent to change state. | Immutable, primitives or serializable structures, no behavior. |
| **Application service / command handler** | Application | Orchestrates command execution. | No business logic; handles transactions and dependencies. |
| **Aggregate root** | Domain | Transactional root and invariant guardian. | Atomic access; hides inner entities; exposes semantic methods. |
| **Domain rules** | Domain | Pure validation, transition, and calculation logic. | Deterministic; operate on entities and value objects with no I/O. |
| **Repository port** | Domain | Collection-like contract for aggregates. | `save`, `findById`; no `IQueryable`, no SQL details. |
| **Repository adapter** | Infrastructure | Technical repository implementation. | Maps tables/documents to the whole aggregate. |
| **Query handler / query service** | Application (read) | Retrieves view-optimized data. | Decoupled from the domain model; queries the read store directly. |
| **Read DTO / projection** | Application (read) | Flat structure shaped for the UI. | Immutable, no behavior, no client-side joins needed. |

## Adoption levels

CQRS is a gradient, not a switch. In increasing cost:

1. **CQS at method level** — always, free.
2. **Separate command and query services** over the same schema — cheap, and solves most cases.
3. **Separate read models** (SQL views, projections) on the same database.
4. **Separate read and write stores** synchronized by events — introduces user-visible eventual consistency and is justified only by real scale.

Move up a level when the level below hurts, not before.

## When it pays

| Criterion | Context |
| :--- | :--- |
| **High business complexity** | Advanced calculation rules, cross-validations, dynamic workflow states (logistics, financial settlement, telecom). |
| **Read/write disparity** | Query volume far exceeds mutation volume (catalogs, analytical dashboards). |
| **Heterogeneous view data** | UIs composing data from several aggregates or contexts without nested ORM bottlenecks. |
| **Rich domain models** | Strict encapsulation and a rigorous split between application orchestration and core business logic. |
| **Query latency requirements** | Sub-tens-of-milliseconds responses via precomputed denormalized views or specialized search indexes. |

## When NOT to use CQRS

- CRUD with no significant business rules: the separation only adds layers.
- Teams that have not yet mastered tactical modeling: CQRS multiplies the cost of a badly drawn model.
- When the business cannot tolerate eventual consistency in reads and you are not willing to keep both stacks on one store.
- Short-lived prototypes and MVPs where the domain model is not yet stable.
- Low-concurrency internal systems where a layered architecture already meets the SLA.

## Questions to answer

1. **Aggregate boundary** — what exactly must stay atomic in one database transaction?
2. **Rule placement** — does this rule belong to one entity, to a composite value object, or does it need a domain service spanning aggregates?
3. **CQRS strategy** — code-level CQRS on one schema, or physically segregated stores with asynchronous synchronization?
4. **Command semantics** — does the command express explicit business intent, or is it a generic CRUD patch?
5. **Clean reconstitution** — can persistence rebuild whole aggregates with their immutable value objects without breaking encapsulation or using public setters?

## Worked example

### Command stack

```typescript
// application/commands/assign-route-to-cargo.command.ts
export class AssignRouteToCargoCommand {
  constructor(public readonly trackingId: string, public readonly legs: LegDTO[]) {}
}

// application/commands/assign-route-to-cargo.handler.ts
export class AssignRouteToCargoHandler {
  constructor(private readonly cargoRepository: CargoRepository) {}

  public async handle(command: AssignRouteToCargoCommand): Promise<void> {
    const trackingId = new TrackingId(command.trackingId);
    const cargo = await this.cargoRepository.findByTrackingId(trackingId);
    if (!cargo) throw new CargoNotFoundError(command.trackingId);

    const legs = command.legs.map(dto => new Leg(
      new Location(dto.loadLocationCode, dto.loadLocationName),
      new Location(dto.unloadLocationCode, dto.unloadLocationName),
      new Date(dto.loadTime),
      new Date(dto.unloadTime),
    ));

    cargo.assignRoute(Itinerary.create(legs));   // domain rules recompute Delivery
    await this.cargoRepository.save(cargo);
  }
}
```

The aggregate keeps the rule. `assignRoute` validates the itinerary against the `RouteSpecification` and rebuilds the immutable `Delivery` value object (`Delivery.derivedFrom(routeSpecification, itinerary)`), marking the cargo misrouted when the specification is not satisfied. The handler never inspects that.

### Query stack

```typescript
// application/queries/cargo-query.service.ts
export interface CargoSummaryDTO {
  trackingId: string;
  originName: string;
  destinationName: string;
  arrivalDeadline: string;
  routingStatus: string;
  transportStatus: string;
  isMisdirected: boolean;
  totalLegs: number;
}

export class CargoQueryService {
  constructor(private readonly dbPool: Pool) {}

  public async getCargoSummary(trackingId: string): Promise<CargoSummaryDTO | null> {
    // Direct read against a denormalized view — the domain model is never hydrated.
    const result = await this.dbPool.query(
      `SELECT c.tracking_id AS "trackingId",
              c.origin_name AS "originName",
              c.destination_name AS "destinationName",
              c.arrival_deadline AS "arrivalDeadline",
              c.routing_status AS "routingStatus",
              c.transport_status AS "transportStatus",
              c.is_misdirected AS "isMisdirected",
              COUNT(l.id) AS "totalLegs"
         FROM cargos_view c
         LEFT JOIN legs_view l ON l.cargo_id = c.id
        WHERE c.tracking_id = $1
        GROUP BY c.tracking_id, c.origin_name, c.destination_name, c.arrival_deadline,
                 c.routing_status, c.transport_status, c.is_misdirected`,
      [trackingId],
    );
    return result.rows[0] ?? null;
  }
}
```

## Relationship to other patterns

- **Hexagonal architecture** — repository ports sit in the domain, ORM/SQL adapters in infrastructure; the query stack is another outbound adapter.
- **Clean architecture** — aggregate in enterprise business rules, command handlers in application business rules, repositories and query handlers in frameworks & drivers.
- **Event Sourcing** — independent of CQRS, combined by decision rather than definition. When they are combined, the query stack is fed by projections built from the event store, because an event store cannot answer relational queries efficiently.

## Limitations

- Segregated databases make reads return slightly stale data until events synchronize.
- Strict separation means more models — commands, domain, persistence entities, read DTOs — and more mapping code.
- Operational complexity: monitoring command pipelines, event buses, and projection synchronization jobs.

## Anti-patterns

- Level 4 from day one "because that's CQRS".
- Queries that traverse the domain repository and rehydrate aggregates just to return a list.
- Commands returning the modified aggregate, leaking the write model into presentation.
- Business logic duplicated in the query stack.
- Assuming CQRS implies Event Sourcing.

## Checklist

- [ ] Queries avoid loading and reconstituting full domain aggregates.
- [ ] Read DTOs are flat and shaped for the UI, needing no complex client-side mapping.
- [ ] Commands express business intent and return no business data.
- [ ] The chosen adoption level is the lowest one that solves the actual pain.
- [ ] No business rule exists in the query stack.
