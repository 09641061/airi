# Infrastructure Persistence

Location: `internal/<context>/infrastructure/persistence/`

The infrastructure layer is the only place that knows about drivers, ORMs, and SQL. The domain stays clean; the application talks to a port.

## Recommended default stack

| Need | Default | Upgrade when |
|------|---------|--------------|
| Database | PostgreSQL | — |
| Driver | `pgx` v5 (`github.com/jackc/pgx/v5`) | — |
| Query style | Plain SQL via `pgxpool.Pool` | Many queries with hand-written scanning → `sqlc` |
| ORM | None | You can justify why a project needs it on a per-context basis |
| Migrations | `golang-migrate` / `goose` / `atlas` | — |

Always use parameterized queries (`$1`, `$2`, …) — never string-concatenated SQL.

## Layout

```
internal/<context>/infrastructure/persistence/
  models/           # persistence-side structs (with JSON/DB tags)
  mappers/          # domain <-> model converters
  order_repository.go        # adapter implementing the domain port
  unit_of_work.go            # application-layer UoW adapter
  migrations/                # SQL migration files
```

For small contexts, `models/` and `mappers/` can live in the same file as the adapter.

## Plain SQL example

```go
// File: internal/order/infrastructure/persistence/order_repository.go
package persistence

import (
    "context"
    "errors"
    "fmt"

    "github.com/jackc/pgx/v5"
    "github.com/jackc/pgx/v5/pgxpool"

    "github.com/acme/platform/order/domain"
    "github.com/acme/platform/order/domain/model/aggregates"
    "github.com/acme/platform/order/domain/model/valueobjects"
    "github.com/acme/platform/order/domain/repositories"
)

type OrderRepository struct {
    db *pgxpool.Pool
}

func NewOrderRepository(db *pgxpool.Pool) *OrderRepository {
    return &OrderRepository{db: db}
}

var _ repositories.OrderRepository = (*OrderRepository)(nil)

func (r *OrderRepository) Save(ctx context.Context, order *aggregates.Order) error {
    const q = `
        INSERT INTO orders (id, customer_id, status, created_at)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status
    `
    _, err := r.db.Exec(ctx, q,
        order.ID().Value(),
        order.CustomerID().Value(),
        string(order.Status()),
        order.CreatedAt(),
    )
    if err != nil {
        return fmt.Errorf("saving order %s: %w", order.ID(), err)
    }
    return nil
}

func (r *OrderRepository) FindByID(ctx context.Context, id valueobjects.OrderID) (*aggregates.Order, error) {
    const q = `SELECT customer_id, status, created_at FROM orders WHERE id = $1`
    var (
        customerID uint64
        status     string
        createdAt  time.Time
    )
    err := r.db.QueryRow(ctx, q, id.Value()).Scan(&customerID, &status, &createdAt)
    if errors.Is(err, pgx.ErrNoRows) {
        return nil, domain.ErrOrderNotFound
    }
    if err != nil {
        return nil, fmt.Errorf("finding order %s: %w", id, err)
    }
    return aggregates.ReconstituteOrder(id, valueobjects.CustomerID(customerID), aggregates.Status(status), createdAt)
}
```

## When to add `sqlc`

Add `sqlc` when:
- More than ~10 hand-written queries and manual `Scan` calls become error-prone.
- The team wants type-safe query code generated from `.sql` files.
- The schema is stable enough that codegen fits the workflow.

`sqlc` still produces code that talks to `pgx` / `database/sql`. The generated code lives in `infrastructure/persistence/queries/` and is consumed by the adapter, never by the domain.

## When (if ever) to use an ORM

The default answer is **no**. An ORM makes sense only when:
- The aggregate-to-table mapping is one-to-one (rare in DDD).
- The team has more time to learn ORM semantics than to write explicit queries.
- The project is read-mostly with simple CRUD and no aggregate invariants.

If an ORM is used, treat it as an internal adapter detail. The domain still owns invariants, and the aggregate methods still enforce them. The ORM is between the repository adapter and the database — the domain and application don't see it.

## Migrations

Keep migrations in `migrations/` (or `infrastructure/persistence/migrations/`) as plain `.sql` files, with up and down pairs. Use `golang-migrate`, `goose`, or `atlas` to apply them. Run migrations as a separate command before the service starts.

## Transactions

Open a transaction through the application-layer `UnitOfWork` port (see `application-services.md`); the `pgx`-backed implementation lives here. Keep transactions short — one use case, no I/O outside the DB call.

## Checklist

- [ ] Only `infrastructure/persistence/` imports `pgx` / `database/sql` / GORM
- [ ] Every query is parameterized
- [ ] Repository adapter implements the domain port and includes a compile-time assertion
- [ ] `pgx.ErrNoRows` (or equivalent) is translated to a typed `domain.ErrX`, not a raw `pgx` error
- [ ] Migrations are plain SQL, versioned, with up/down pairs
- [ ] ORM (if any) is fully inside `infrastructure/persistence/`
