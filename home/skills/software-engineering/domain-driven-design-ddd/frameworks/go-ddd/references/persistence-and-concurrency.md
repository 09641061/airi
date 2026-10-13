# Persistence adapters and optimistic concurrency

The domain repository port is independent of the datastore. Implement it in `infrastructure/persistence/<backend>` and keep database records and driver errors there. The adapter loads a complete aggregate, maps "not found" to `domain.ErrOrderNotFound`, and reconstitutes through `domain.ReconstituteOrder`.

## Per-store strategies

Pick the strategy that fits the store; do not lift one store's rules into another.

### Relational SQL

- Use the driver/query layer you prefer (`database/sql`, a vendor driver, an ORM, or another client).
- Persist the aggregate in a transaction; use constraints and a tenant-scoped key.
- Translate driver-specific not-found and conflict errors at the adapter boundary.
- Optimistic concurrency: `UPDATE orders SET version = version + 1, ... WHERE tenant_id = $1 AND id = $2 AND version = $3`. Zero rows updated → `domain.ErrConcurrentModification`.

### Document databases

- Store an aggregate as one document when its size and lifecycle allow; embed only data inside that aggregate boundary.
- Map documents through the domain reconstitution factory — never set fields via reflection or setters.
- Include tenant and version in the update filter. Example for MongoDB:
  ```javascript
  db.orders.updateOne(
    { tenantId: tid, _id: oid, version: expected },
    { $set: { status: "Submitted", version: expected + 1, /* … */ } }
  )
  ```
  Zero matched documents means a conflict (`ErrConcurrentModification`).

### Key-value stores

- Include tenant and aggregate identity in the key/partition key, then use native compare-and-swap or conditional writes.
- Example for DynamoDB: `ConditionExpression: "#v = :expected"` on `UpdateItem`; a `ConditionalCheckFailedException` maps to `ErrConcurrentModification`.
- Treat TTL and item-size limits as aggregate boundary constraints; do not split one aggregate across multiple items.

### Search / analytics stores

- Treat them as read projections, not the authoritative aggregate repository, unless the domain explicitly assigns them that role.
- If a search store is the system of record (rare), you must still enforce optimistic concurrency on its write path; do not assume search engines provide it.

## Atomicity across records

Prefer one atomic document/item per aggregate. If an aggregate spans multiple records, use the store's transaction when available or **reconsider the boundary**; do not assume cross-record atomicity.

## What "optimistic concurrency" means here

`VersionedOrder.Version` is a token the store owns. The flow:

1. Repository returns `VersionedOrder{Order, Version}` from `FindByID`.
2. Application service mutates the aggregate in memory.
3. `Save(ctx, tenant, order, expectedVersion)` issues an atomic conditional update.
4. The store compares the expected version with the stored version in the same write.
5. Mismatch → `domain.ErrConcurrentModification`. Caller decides: reload, merge, or fail.

The cardinal rule: **do not read, check in Go, then write unconditionally — that leaves a race window.** The comparison must happen inside the store's atomic write.

## Adapter responsibilities (recap)

- Map driver "not found" → `domain.ErrOrderNotFound`.
- Map driver "conflict / zero rows / conditional check failed" → `domain.ErrConcurrentModification`.
- Wrap with `%w` so callers can classify with `errors.Is`.
- Keep SQL / BSON / DynamoDB types inside the adapter. Do not let them leak into domain or application.

## Integration tests

Test against the actual database or a compatible test service (testcontainers, ephemeral Postgres, DynamoDB Local, etc.). Cover at least:

- Reconstitute round-trip (write → read → ReconstituteOrder matches the original).
- Stale-write rejection (`Save` with the wrong `expectedVersion` returns `ErrConcurrentModification`).
- Tenant isolation (queries never return rows from another tenant).
- Constraints (duplicate keys, FK violations, invalid status transitions on data).
- Transaction rollback when a partial failure occurs inside the adapter.