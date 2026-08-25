# Step 4 — Tactical building blocks

The building blocks are the vocabulary for modeling the inside of a bounded context. Their goal is that **the model expresses business rules in code**, not that it serves as a data structure for the database.

## Rich model vs. anemic model

| Criterion | Anemic model (anti-pattern) | Rich domain model |
| :--- | :--- | :--- |
| **Where logic lives** | In `*Service` classes or controllers. | Inside entities and value objects. |
| **Encapsulation** | Weak or none; public getters/setters expose internal state. | Strict; private state, mutation only through semantic methods. |
| **Invariant guarantee** | Impossible; any client can call a setter and corrupt the state. | Guaranteed in the constructor and in every mutator. |
| **Cohesion** | Low; data in one class, behavior in another. | High; data and behavior live together. |
| **Testability** | Requires heavy mocking of services and dependencies. | Pure, direct unit tests on domain objects. |

An **invariant** is a business rule that must hold true at all times throughout an object's lifecycle: *"an order cannot be confirmed with no items"*, *"the item total plus shipping must equal the order total exactly"*, *"an account balance cannot fall below its agreed overdraft limit"*.

Two consistency frontiers:
- **Immediate (strong, atomic) consistency** — inside a single aggregate, validated synchronously in the same ACID transaction.
- **Eventual consistency** — between aggregates (same or different context), propagated asynchronously through domain events.

## The blocks

### 1. Entity
Defined not by its attributes but by a thread of continuity and a unique, immutable identity over time.
- Holds a unique identifier (`OrderId`, `UserId`, a UUID).
- Two entities with identical attributes are different if their identities differ.
- Has a lifecycle with multiple state transitions.
- Equality is evaluated **exclusively** through the identifier, never by values.

### 2. Value object
Describes a descriptive aspect of the domain with no conceptual identity. The most underused block and the one that absorbs the most rules.
- **Absolute immutability** — once created, state cannot mutate; any modification produces a new instance (side-effect-free function).
- **Structural equality** — two value objects are identical if all attributes are equal by value.
- **Atomic self-validation** — validates its own invariants in the constructor. A value object can never exist in a corrupt or incomplete state.
- **Replaceability** — to change a value, replace the whole instance in the owning entity.
- Examples: `Money`, `EmailAddress`, `PostalAddress`, `Quantity`, `DateRange`.

### 3. Aggregate and aggregate root
A cluster of entities and value objects treated as one atomic unit for modification and invariant enforcement. The **aggregate root** is the only externally visible entity; all outside access goes through it.
- External objects may hold references only to the root, never to inner entities.
- Inner entities have local identity, valid only inside the aggregate.
- The root validates every invariant of every contained object before changes are persisted.
- Sizing rules are in [aggregate-boundaries.md](aggregate-boundaries.md).

### 4. Domain event
An immutable record of a business-relevant fact that **has already happened**.
- Named strictly in the past tense (`OrderPlaced`, `InvoiceGenerated`, `UserRegistered`). Imperative names are commands, not events.
- Immutable; carries `occurredOn` and the emitting aggregate's identifier.
- Decouples internal components and propagates state changes through eventual consistency.
- Should carry enough information for other contexts to act without a coupled synchronous callback.

### 5. Domain service
A significant business operation that does not belong naturally to any entity or value object, typically because it spans several aggregates or is a complex stateless calculation.
- **Stateless**; stores nothing between executions.
- Uses the ubiquitous language in its interface and methods.
- Not the same as an **application service**, which orchestrates use cases, transactions, and security and contains no rules.

### 6. Repository
A mechanism that simulates an in-memory collection of whole aggregates.
- **One repository per aggregate root** — never one per table, never one for an inner entity or value object.
- The interface belongs to the domain layer; the implementation lives in infrastructure.
- Provides atomic persistence and lookup (`save`, `findById`, `delete`).

### 7. Factory
Encapsulates the creation of aggregates or complex value objects that need structured assembly or pre-instantiation validation.
- Guarantees the aggregate is returned fully valid with all initial invariants satisfied.
- Implemented as a static factory method on the aggregate itself, or as a standalone class when creation involves external dependencies.

## Working rules

1. **Start with value objects.** Every primitive with rules (an email, an amount, a date range) is a candidate. Converting it removes duplicated validation and makes invalid state unrepresentable.
2. **The rule lives where its data is.** One aggregate's data → put it in the aggregate. Several aggregates' data → domain service.
3. **One aggregate, one transaction.** Modifying two aggregates in the same transaction means the boundary is wrong — or the second change belongs in a domain event handler.
4. **The domain knows no infrastructure.** No ORM, no HTTP, no framework. If the model imports a persistence annotation, the dependency points the wrong way.

## Structural guide

| Component | Access modifiers | Mutability | Invariant validation | Equality |
| :--- | :--- | :--- | :--- | :--- |
| **Value object** | Private/protected constructor, public factory methods. | Immutable (`readonly` / `final` fields). | In the constructor/factory; fail fast on invalid data. | Structural, by all attributes. |
| **Inner entity** | Package-scoped or encapsulated inside the aggregate module. | Mutable through business methods. | In constructors and mutators. | By local identifier. |
| **Aggregate root** | Public to the application layer; constructors protected/private. | Mutable only through its public business methods. | In every mutating operation; protects all inner entities. | By globally unique identifier. |
| **Domain event** | Public, read-only properties. | Strictly immutable. | At instantiation. | By `eventId`. |
| **Domain service** | Public, stateless methods. | No internal state. | Validates cross-aggregate operations. | Not applicable. |

## Modeling order

1. **Extract the ubiquitous language** — key nouns (*order*, *order line*, *currency*, *customer*, *address*) and action verbs (*confirm*, *cancel*, *ship*, *refund*) from the agreed glossary.
2. **Identify invariants and atomic rules** — separate those needing immediate consistency from those tolerating delay.
3. **Model value objects** — turn every primitive with validation, unit of measure, or behavior into an immutable value object (`Money`, `Email`, `Quantity`, `Sku`).
4. **Delimit entities and aggregate roots** — cluster dependent entities around one root; apply Vernon's four rules.
5. **Define domain events** — immutable classes for the business facts produced by each relevant mutation.
6. **Design repository interfaces** — in the domain layer, only for aggregate roots.
7. **Orchestrate use cases with application services** — see [object-lifecycle.md](object-lifecycle.md).

## Runtime flow

1. The interface layer receives a request and sends it to an application service as a command/DTO.
2. The application service fetches the whole aggregate root from the repository by id.
3. It invokes semantic methods on the root; the root validates invariants and updates internal state.
4. If the operation matters to the rest of the system, the root records one or more domain events internally.
5. The application service persists the modified aggregate **and its events in one atomic transaction**.
6. The stored events are dispatched asynchronously (transactional outbox) to update projections or trigger work in other aggregates.

## Questions to answer while modeling

**Value objects** — does this concept need its own identity or does it only describe a characteristic or quantity? If two instances share all field values, are they interchangeable? Is it fully immutable and self-validating?

**Aggregates** — which invariants must hold atomically and synchronously? Is the aggregate small enough, or does it contain entities that could be managed asynchronously? Are all references to other aggregates made through identifiers? Is there more than one root inside this transactional boundary? (If yes, split it.)

**Domain events** — does the name describe precisely something that already happened, in the domain experts' language? Does it carry everything other contexts need in order to act without a coupled synchronous query?

## Good practices

1. **Private constructors plus factory methods** — force instantiation through explicit business names (`Order.create()`, `Account.openWithDeposit()`), guaranteeing invariants from birth.
2. **Value objects strictly immutable** — never a mutator; produce a new instance instead.
3. **Expose collections read-only** — never return the internal mutable list (`return [...this.items]`, or an unmodifiable collection).
4. **Keep aggregates small** — beyond three to five inner entities, re-evaluate whether they truly need immediate transactional consistency.
5. **Separate application services from domain services** — application services orchestrate infrastructure, security, and transactions; domain services run pure business logic.
6. **Use the transactional outbox** — never publish events straight to a broker in the middle of a domain transaction; persist the event in the same transaction and dispatch it asynchronously.
7. **Keep persistence annotations out of the domain** — no `@Entity`/`@Table`/`@Column` on domain classes; use separate infrastructure entities with explicit mappers when the ORM demands it.

## Worked model sketch (order management)

```typescript
// Value object: immutable, self-validating, structural equality.
export class Money {
  private constructor(private readonly amount: number, private readonly currency: string) {}

  public static of(amount: number, currency: string): Money {
    if (amount < 0) throw new Error('Amount cannot be negative.');
    if (!currency || currency.length !== 3) throw new Error('Currency must be a 3-letter ISO code.');
    return new Money(Math.round(amount * 100) / 100, currency.toUpperCase());
  }

  public static zero(currency = 'USD'): Money { return Money.of(0, currency); }

  public add(other: Money): Money {
    if (this.currency !== other.currency) {
      throw new Error(`Cannot add ${this.currency} to ${other.currency}.`);
    }
    return Money.of(this.amount + other.amount, this.currency);
  }

  public equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency;
  }
}

// Domain event: past tense, immutable.
export class OrderPlaced {
  public readonly occurredOn = new Date();
  constructor(
    public readonly orderId: string,
    public readonly customerId: string,
    public readonly totalAmount: number,
    public readonly currency: string,
  ) {}
}

// Aggregate root: private state, semantic methods, invariants enforced on every mutation.
export class Order {
  private readonly items: OrderItem[] = [];
  private status: OrderStatus = OrderStatus.DRAFT;
  private events: DomainEvent[] = [];

  private constructor(
    private readonly id: OrderId,
    private readonly customerId: CustomerId,
    private readonly currency: string,
  ) {}

  public static create(id: OrderId, customerId: CustomerId, currency: string): Order {
    return new Order(id, customerId, currency);
  }

  public addItem(productId: string, unitPrice: Money, quantity: number): void {
    this.assertDraft();
    if (quantity <= 0) throw new Error('Quantity must be positive.');
    this.items.push(new OrderItem(productId, unitPrice, quantity));
  }

  public place(): void {
    this.assertDraft();
    if (this.items.length === 0) throw new Error('An order cannot be placed with no items.');
    this.status = OrderStatus.PLACED;
    const total = this.total();
    this.events.push(new OrderPlaced(this.id.value, this.customerId.value, total.value, this.currency));
  }

  public pullEvents(): DomainEvent[] {
    const pulled = this.events;
    this.events = [];
    return pulled;
  }

  private total(): Money {
    return this.items.reduce((acc, item) => acc.add(item.subtotal()), Money.zero(this.currency));
  }

  private assertDraft(): void {
    if (this.status !== OrderStatus.DRAFT) throw new Error('Order is no longer editable.');
  }
}
```

## Limitations

- Steep learning curve for developers used to table-driven, anemic models.
- Over-engineering in simple domains: full tactical design on a low-complexity system produces redundant code.
- Friction with traditional ORMs: mapping rich aggregates with private constructors, encapsulated fields, and immutable value objects requires advanced mapping configuration or intermediate adapters.
- Eventual-consistency complexity: synchronizing aggregates through events needs the transactional outbox, consumer idempotency, and queue monitoring.

## Checklist

- [ ] Domain classes use terms drawn strictly from the ubiquitous language.
- [ ] No public setters allow mutating state without validating rules.
- [ ] Every descriptive or quantifiable concept is an immutable, self-validating value object.
- [ ] Each aggregate has exactly one root through which all mutations are channelled.
- [ ] Repositories are domain-layer interfaces and exist only for aggregate roots.
- [ ] The domain layer has no infrastructure, third-party, or ORM dependencies.
- [ ] Unit tests for aggregates and value objects run in memory in milliseconds, with no database or container.
