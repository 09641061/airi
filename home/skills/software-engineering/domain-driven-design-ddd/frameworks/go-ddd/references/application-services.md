# Application Services (Use Cases)

Location: `internal/<context>/application/`

Application services orchestrate use cases. They depend on the **domain** (to load aggregates, invoke business methods, save) and on **infrastructure** (to open transactions, publish events, send notifications). They are **not** part of the domain and must not be placed in `domain/services/`.

> The "domain services" guide (`domain-services.md`) covers pure business logic that doesn't fit an entity. The "commands and queries" guide (`commands-and-queries.md`) covers when to introduce explicit `*Command` / `*Query` types. This file covers the default case: an application service that exposes use cases directly through input structs.

## Default shape — input struct + result

For most contexts, the application service exposes a method per use case, with an input struct for parameters and either an aggregate or a value object as the result.

- **Naming**: `<Entity>Service` or `<Context>Service`. The user-facing contract in the interfaces layer is a separate interface; the implementation is unexported.
- **Methods**: `CreateOrder`, `ConfirmOrder`, `FindOrder`, etc. Use the business verb, not `Handle`. Go has no overloading, so `Handle` + `HandleUpdate` in the same interface is a smell — name the method after the operation.
- **First parameter is always `context.Context`.** Propagate it through repositories, publishers, ACL facades.
- **Return at most one `(result, error)`.** If you need to return multiple things, return a small struct.

## Example

```go
// File: internal/order/application/order_service.go
package application

import (
    "context"
    "fmt"
    "time"

    "github.com/acme/platform/order/domain"
    "github.com/acme/platform/order/domain/model/aggregates"
    "github.com/acme/platform/order/domain/model/valueobjects"
    "github.com/acme/platform/order/domain/repositories"
)

type Clock interface {
    Now() time.Time
}

type OrderService struct {
    orders repositories.OrderRepository
    clock  Clock
}

func NewOrderService(
    orders repositories.OrderRepository,
    clock Clock,
) *OrderService {
    return &OrderService{orders: orders, clock: clock}
}

type CreateOrderInput struct {
    CustomerID valueobjects.CustomerID
}

func (s *OrderService) CreateOrder(ctx context.Context, input CreateOrderInput) (*aggregates.Order, error) {
    id, err := valueobjects.NewOrderID(generateID())
    if err != nil {
        return nil, err
    }
    order, err := aggregates.NewOrder(id, input.CustomerID, s.clock.Now())
    if err != nil {
        return nil, err
    }
    if err := s.orders.Save(ctx, order); err != nil {
        return nil, fmt.Errorf("creating order: %w", err)
    }
    return order, nil
}

func (s *OrderService) ConfirmOrder(ctx context.Context, id valueobjects.OrderID) error {
    order, err := s.orders.FindByID(ctx, id)
    if err != nil {
        return err
    }
    if _, err := order.Confirm(s.clock.Now()); err != nil {
        return err
    }
    return s.orders.Save(ctx, order)
}
```

## Transactions

The application service is the right place to open a transaction when one use case touches multiple aggregates. Don't push the transaction abstraction into the domain.

```go
type UnitOfWork interface {
    WithinTx(ctx context.Context, fn func(ctx context.Context) error) error
}

func (s *OrderService) PlaceOrderWithPayment(ctx context.Context, input PlaceOrderInput) error {
    return s.uow.WithinTx(ctx, func(ctx context.Context) error {
        order, err := s.orders.FindByID(ctx, input.OrderID)
        if err != nil {
            return err
        }
        if err := order.MarkReadyForPayment(); err != nil {
            return err
        }
        if err := s.orders.Save(ctx, order); err != nil {
            return err
        }
        return s.payments.Authorize(ctx, order.ID(), order.Total())
    })
}
```

The `UnitOfWork` is an application-layer port; the `pgx`-backed implementation lives in `infrastructure/persistence/`.

## What NOT to put in an application service

- **Business rules** — those belong on the aggregate. The application service should not contain `if order.Status == "pending" { order.Status = "confirmed" }`; it should call `order.Confirm(now)`.
- **HTTP concerns** — no `*gin.Context`, no `http.ResponseWriter`. The interfaces layer is responsible.
- **Database plumbing** — no raw SQL, no `pgxpool.Pool` directly. Inject repository ports.

## Naming principle reminder

| Purpose | File / type name | Method name |
|---------|------------------|-------------|
| Order use cases | `order_service.go` / `OrderService` | `CreateOrder`, `ConfirmOrder`, `FindOrder` |
| ACL facade (provider) | `<context_b>_facade.go` / `<ContextB>Facade` | `CreateEntity`, `FindEntityIDByField` |
| ACL outbound service (consumer) | `external_<entity>_service.go` / `External<Entity>Service` | `FetchEntityByField`, `CreateEntity` |
| Outbox publisher port | `event_publisher.go` / `EventPublisher` | `Record`, `Publish` |

Never name two methods in the same interface `Handle` and `HandleUpdate` — Go has no overloading, so the only way to disambiguate is the suffix. Make the suffix the operation name from the start.

## Checklist

- [ ] Service struct is in `application/`, not in `domain/`
- [ ] Each method takes `context.Context` as the first parameter
- [ ] Methods return at most one result and one error
- [ ] No business rules inside the service — those live on the aggregate
- [ ] No HTTP, gRPC, or driver import in `application/`
- [ ] Transactions are managed at this layer via a `UnitOfWork` port, not inside the aggregate
- [ ] Method names describe the operation (`ConfirmOrder`), not the verb `Handle` plus a parameter
