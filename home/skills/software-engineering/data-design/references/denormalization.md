# Deliberate denormalization

Denormalization is the deliberate, justified reintroduction of redundancy into a normalized (3NF/BCNF) schema, for the exclusive purpose of optimizing read-heavy queries. It happens **after** normalization, never instead of it.

## The three preconditions

Do not denormalize unless all three hold:

1. A **measured** performance problem — profiling evidence, `EXPLAIN ANALYZE` on the real plan, not an intuition about future load.
2. An identified guilty query or query family, with the cost attributed to the joins you intend to remove.
3. An explicit mechanism that keeps the duplicated data consistent.

Then record the decision with its reason next to the schema. Undocumented denormalization is read as a mistake by the next person, and gets "fixed".

## Consistency mechanisms

Pick one and name it in the documentation:

- **Transactional triggers** — the duplicate is updated in the same transaction. Strong consistency, hidden control flow, engine-specific.
- **Materialized views with scheduled refresh** — the redundancy is derived and explicitly stale by a known bound. The safest option when a staleness window is acceptable.
- **Asynchronous domain events** — the write model publishes, projections update. Eventual consistency, and the natural fit when the read model is already separated by [CQRS](../../domain-driven-design-ddd/ddd-core/references/cqrs.md).
- **Computed/generated columns** — when the derivation is local to the row, let the engine do it rather than the application.

Duplication with no mechanism is not denormalization; it is divergence with extra steps.

## Common shapes

- **Precomputed aggregates** — `orders.total_amount`, `posts.comment_count`. Cheap, high-value, easy to drift; the classic case for a trigger or an event.
- **Copied descriptors** — `order_items.product_name` at purchase time. Frequently *not* denormalization at all: the historical value is a genuinely different fact from the current one, and copying it is correct modeling.
- **Flattened hierarchies** — materialized paths or closure tables to avoid recursive queries.
- **Read models / projections** — the whole query side rebuilt in a shape that matches the screen. Prefer this over degrading the normalized write model.

## Alternatives to try first

Before trading away the normal form, exhaust the cheaper moves: a missing index (especially on a foreign key), a covering or partial index, a rewritten query, a projection selecting only required columns, a fetch strategy fix in the ORM (see [orm-impedance.md](orm-impedance.md)), partitioning, or a cache with an explicit TTL. Most "we need to denormalize" diagnoses are an unindexed FK or an N+1.

## What you are giving up

Every denormalization buys read latency with write cost, write complexity, and a new class of bug: silent divergence between two representations of the same fact. Make that price visible in the decision record.
