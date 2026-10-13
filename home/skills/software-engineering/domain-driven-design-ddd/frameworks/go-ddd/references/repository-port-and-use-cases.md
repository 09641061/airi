# Repository port and use cases

The repository interface is a domain port. Its version is an optimistic-concurrency token, not business state. Application services orchestrate create, add-line, and submit. Notice the constructor takes `domain.OrderRepository`; the port is **not** redeclared in `application`.

Keep `%w` when wrapping errors so adapters can classify them with `errors.Is`. Add a unit-of-work only when a use case needs atomic work across multiple repository operations.

## Repository port

```go
// internal/orders/domain/order_repository.go
package domain

import "context"

type VersionedOrder struct {
    Order   *Order
    Version int64
}

type OrderRepository interface {
    Create(ctx context.Context, tenant TenantID, order *Order) error
    FindByID(ctx context.Context, tenant TenantID, id ID) (VersionedOrder, error)
    Save(ctx context.Context, tenant TenantID, order *Order, expectedVersion int64) error
}
```

## Application service

```go
// internal/orders/application/service.go
package application

import (
    "context"
    "fmt"

    "example.com/shop/internal/orders/domain"
)

type IDGenerator interface{ NewID() string }

type OrderService struct {
    orders domain.OrderRepository
    ids    IDGenerator
}

func NewOrderService(orders domain.OrderRepository, ids IDGenerator) *OrderService {
    return &OrderService{orders: orders, ids: ids}
}

func (s *OrderService) CreateOrder(ctx context.Context, tenant domain.TenantID) (domain.ID, error) {
    order, err := domain.NewOrder(s.ids.NewID())
    if err != nil {
        return "", err
    }
    if err := s.orders.Create(ctx, tenant, order); err != nil {
        return "", fmt.Errorf("create order: %w", err)
    }
    return order.ID(), nil
}

func (s *OrderService) AddLine(ctx context.Context, tenant domain.TenantID, id domain.ID, sku string, quantity int) error {
    stored, err := s.orders.FindByID(ctx, tenant, id)
    if err != nil {
        return fmt.Errorf("find order: %w", err)
    }
    if err := stored.Order.AddLine(sku, quantity); err != nil {
        return err
    }
    return s.orders.Save(ctx, tenant, stored.Order, stored.Version)
}

func (s *OrderService) SubmitOrder(ctx context.Context, tenant domain.TenantID, id domain.ID) error {
    stored, err := s.orders.FindByID(ctx, tenant, id)
    if err != nil {
        return fmt.Errorf("find order: %w", err)
    }
    if err := stored.Order.Submit(); err != nil {
        return err
    }
    return s.orders.Save(ctx, tenant, stored.Order, stored.Version)
}
```

## Rules to enforce

- The application service depends on `domain.OrderRepository`, not on a concrete adapter.
- Domain errors from `Order.AddLine` / `Order.Submit` propagate **untouched** (no `%w` wrapping) so the transport adapter can classify them with `errors.Is`.
- Infrastructure errors (`Create`, `FindByID`, `Save` failures) are wrapped with `%w` and a stable verb prefix (`create order`, `find order`) so callers can still classify.
- External-system ports (like `IDGenerator`) live next to the use case that consumes them, not in a generic "infrastructure" bucket.