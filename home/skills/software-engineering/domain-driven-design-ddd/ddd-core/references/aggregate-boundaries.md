# Step 5 — Aggregate boundaries: Vaughn Vernon's four rules

Four rules decide **what goes inside an aggregate and what stays outside**. They are the most practical criterion in all of tactical design, because a badly sized aggregate degrades consistency, performance, and concurrency simultaneously.

## Rule 1 — Protect true business invariants inside the consistency boundary

Only what must be consistent **immediately and transactionally** belongs in the aggregate. For every rule, ask: does the business tolerate this being true one second later? If it does, it is not an aggregate invariant and does not justify growing the boundary. Most rules that look like they demand immediate consistency do not.

Ask the business — do not assume.

## Rule 2 — Design small aggregates

The ideal aggregate is a root plus its value objects. Every extra entity adds load time, contention risk, and conflict surface. A small aggregate loads fast, locks little, and scales; a *god aggregate* holding the whole object graph (a `Customer` containing every invoice, order, address, and payment) does the opposite on all three dimensions and produces massive lock contention, memory pressure, and ORM slowness.

Rule of thumb: beyond three to five inner entities, re-check whether they really need immediate transactional consistency.

## Rule 3 — Reference other aggregates by identity only

Never hold a direct object reference or in-memory pointer to another aggregate (`Order.customer: Customer`). Store its identifier instead (`Order.customerId: CustomerId`).

This keeps the boundary explicit, avoids cascading loads and accidental cascading saves, prevents modifying another aggregate in the same transaction, and allows horizontal scaling. If you need data from the other aggregate to make a decision, load it in the application service and pass it in as an argument.

## Rule 4 — Use eventual consistency outside the boundary

One transaction, one aggregate instance. Whatever must change in other aggregates propagates through **domain events** processed afterwards. If a requirement seems to demand modifying two or more aggregates inside the same ACID transaction, that is a clear symptom that the boundaries are wrong.

This is the rule most teams break first, and it is the one that holds up the other three: without it, rule 2 is impossible to satisfy.

## How to apply them

1. List the business rules the model must guarantee.
2. For each, decide whether it requires **immediate** consistency or tolerates delay. Ask the business.
3. Only the immediate ones define aggregate boundaries; group by those.
4. Everything else becomes a domain event and its handler.
5. Replace direct references between aggregates with identifiers.
6. Verify: does any operation still modify two aggregates at once? If so, go back to step 2.

## Signals that a boundary is wrong

- A transaction saving two aggregate roots.
- An aggregate loaded with a `JOIN` across five tables just to change one field.
- Frequent optimistic-concurrency conflicts on the same root.
- Unbounded collections inside an aggregate (a customer holding all their orders) that grow without a cap.
- Needing to navigate `order.getCustomer().getAddress()` from another aggregate.

## Anti-patterns

| Anti-pattern | Technical manifestation | Consequence | Fix |
| :--- | :--- | :--- | :--- |
| **God aggregate** | One massive aggregate holding the entire domain object graph. | Concurrent lock contention, memory problems, extreme ORM slowness. | Split into small aggregates referenced only by ID. |
| **Direct pointer references** | An aggregate typed with another aggregate as a property. | Forced transactional coupling and accidental cascading saves. | Replace the reference with the identifier value object. |
| **Multi-aggregate transaction** | One database transaction modifies two or more aggregate instances. | Concurrency bottlenecks and violated consistency boundaries. | One aggregate per transaction; update the rest via domain events. |
| **Logic leaking into the repository** | Repository queries computing business totals or altering state. | The repository becomes a disguised domain service. | The repository only persists and retrieves aggregates; calculation belongs in the aggregate or a domain service. |
| **Anemic domain model** | Entities made only of public getters and setters. | Logic scatters into procedural services; invariants are unenforceable. | Move logic and validation into entities and value objects; encapsulate state. |

## Checklist

- [ ] Each aggregate has exactly one root through which all mutations pass.
- [ ] Aggregates hold no direct pointers to other aggregates; they communicate only through identifiers.
- [ ] Each database transaction modifies and persists exactly one aggregate instance.
- [ ] Dependencies between aggregates are resolved through eventual consistency and domain events.
- [ ] No aggregate contains an unbounded collection.
- [ ] Repositories exist only for aggregate roots and are defined as domain-layer interfaces.
