# Repositories: domain port + infrastructure adapter

Repositories are split into two files: a **port** (domain interface) and an **adapter** (infrastructure implementation). The port is what the application code depends on; the adapter is what the database driver talks to.

## Port — domain layer

Location: `internal/<context>/domain/repositories/`

- One port **per aggregate root** — never per table, never per child entity.
- The port is a plain Go interface with **no driver, no ORM, no framework imports**.
- It receives and returns whole aggregates and value objects only. It never exposes `pgxpool.Pool`, `*sql.DB`, GORM, `sqlx`, or any persistence abstraction.
- Method names speak the ubiquitous language (`FindByOrderNumber`, not `FindByOrderNumPGX`).
- The collection semantics are minimal: `Save`, `FindByID`, plus aggregate-specific finders when needed. No generic CRUD.

### Example

```go
// File: internal/order/domain/repositories/order_repository.go
package repositories

import (
    "context"

    "github.com/acme/platform/order/domain/model/aggregates"
    "github.com/acme/platform/order/domain/model/valueobjects"
)

type OrderRepository interface {
    Save(ctx context.Context, order *aggregates.Order) error
    FindByID(ctx context.Context, id valueobjects.OrderID) (*aggregates.Order, error)
    FindByCustomer(ctx context.Context, customerID valueobjects.CustomerID) ([]*aggregates.Order, error)
}
```

## Adapter — infrastructure layer

Location: `internal/<context>/infrastructure/persistence/`

- Implements the **domain port** above. `pgx`, `sqlx`, `sqlc`, or GORM may be used internally; the port never sees these types.
- The adapter depends on an internal mapper between a persistence-side model (in `infrastructure/persistence/models/`) and the domain aggregate. The mapper belongs to infrastructure, never to the domain.
- For value objects with unexported fields (Option B in Core rule 6), the model has exported fields and the mapper calls `NewMoney(...)` to rebuild the domain object.

### Example with `pgx` + plain SQL

```go
// File: internal/order/infrastructure/persistence/order_repository.go
package persistence

import (
    "context"
    "errors"
    "fmt"

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

// Compile-time assertion: the adapter implements the port.
var _ repositories.OrderRepository = (*OrderRepository)(nil)

func (r *OrderRepository) Save(ctx context.Context, order *aggregates.Order) error {
    const q = `
        INSERT INTO orders (id, customer_id, status, created_at)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (id) DO UPDATE
        SET status = EXCLUDED.status
    `
    _, err := r.db.Exec(ctx, q,
        order.ID().Value(),
        order.CustomerID().Value(),
        order.Status(),
        order.CreatedAt(),
    )
    if err != nil {
        return fmt.Errorf("saving order: %w", err)
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
    // Rebuild the aggregate through its factory / reconstitute path.
    return aggregates.ReconstituteOrder(id, customerID, aggregates.Status(status), createdAt)
}
```

> `ReconstituteOrder` is a constructor that bypasses business validation — used only by repositories loading from a trusted source. Don't expose it from the application service.

## Mapper split

For aggregates that use unexported fields, the mapper is mandatory:

```go
// File: internal/order/infrastructure/persistence/models/order_model.go
package models

type OrderModel struct {
    ID         uint64
    CustomerID uint64
    Status     string
    CreatedAt  time.Time
}

// File: internal/order/infrastructure/persistence/mappers/order_mapper.go
package mappers

func OrderToModel(o *aggregates.Order) models.OrderModel {
    return models.OrderModel{
        ID:         o.ID().Value(),
        CustomerID: o.CustomerID().Value(),
        Status:     string(o.Status()),
        CreatedAt:  o.CreatedAt(),
    }
}

func ModelToOrder(m models.OrderModel) (*aggregates.Order, error) {
    id, err := valueobjects.NewOrderID(m.ID)
    if err != nil {
        return nil, err
    }
    customerID, err := valueobjects.NewCustomerID(m.CustomerID)
    if err != nil {
        return nil, err
    }
    return aggregates.ReconstituteOrder(id, customerID, aggregates.Status(m.Status), m.CreatedAt)
}
```

## Testing split

- **Domain port tests** — none (the port is an interface; it is tested through the application service, with a stub in-memory or fake implementation of the port).
- **Infrastructure adapter tests** — integration tests that exercise real SQL against PostgreSQL (Testcontainers or a local instance). Mark them with `//go:build integration`.
- **Don't mock the database driver** (`pgxmock`, `sqlmock`). The repository adapter is the boundary under test, not the driver.

## Checklist

- [ ] Domain port interface lives in `domain/repositories/`
- [ ] Domain port imports nothing from `net/http`, `pgx`, `database/sql`, `gorm`, or any driver
- [ ] One port per aggregate root; child entities have no port
- [ ] Method names use the ubiquitous language
- [ ] Adapter lives in `infrastructure/persistence/`, implements the domain port
- [ ] Mapper between persistence model and domain aggregate lives in `infrastructure/persistence/mappers/`
- [ ] `var _ Port = (*Adapter)(nil)` compile-time assertion is present
