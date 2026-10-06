# Entities and Aggregates

Location: `internal/<context>/domain/model/aggregates/` (or `domain/` for small contexts)

- **An entity has identity and lifecycle.**
- **An aggregate groups entities and value objects that must remain consistent together.** The aggregate root is the only object the rest of the system holds a reference to.
- **All mutations to the aggregate go through methods on the root.** No external code sets fields directly.
- **Boundaries are defined by business consistency, not by database tables.** Don't make an aggregate per row.
- **Keep aggregates small.** If two pieces of data can be consistent eventually, they belong in different aggregates.

## Example

```go
// File: internal/order/domain/model/aggregates/order.go
package aggregates

import (
    "time"

    "github.com/acme/platform/order/domain"
    "github.com/acme/platform/order/domain/model/valueobjects"
)

type Status string

const (
    StatusPending   Status = "pending"
    StatusConfirmed Status = "confirmed"
    StatusCancelled Status = "cancelled"
)

type Item struct {
    ProductID valueobjects.ProductID
    Quantity  int
    UnitPrice valueobjects.Money
}

type Order struct {
    id        valueobjects.OrderID
    customerID valueobjects.CustomerID
    status    Status
    items     []Item
    createdAt time.Time
}

// NewOrder is the business-meaningful factory. Validation lives here.
func NewOrder(id valueobjects.OrderID, customerID valueobjects.CustomerID, now time.Time) (*Order, error) {
    if customerID.IsZero() {
        return nil, domain.ErrInvalidCustomer
    }
    return &Order{
        id:        id,
        customerID: customerID,
        status:    StatusPending,
        items:     []Item{},
        createdAt: now,
    }, nil
}

func (o *Order) ID() valueobjects.OrderID { return o.id }
func (o *Order) Status() Status          { return o.status }
func (o *Order) Items() []Item           { append([]Item(nil), o.items...) } // defensive copy

func (o *Order) AddItem(item Item) error {
    if o.status != StatusPending {
        return domain.ErrOrderClosed
    }
    o.items = append(o.items, item)
    return nil
}

func (o *Order) Confirm(now time.Time) error {
    if o.status != StatusPending {
        return domain.ErrCannotConfirmOrder
    }
    if len(o.items) == 0 {
        return domain.ErrCannotConfirmEmptyOrder
    }
    o.status = StatusConfirmed
    o.confirmedAt = now
    return nil
}
```

**Notice:** business rules (`ErrOrderClosed`, `ErrCannotConfirmOrder`, `ErrCannotConfirmEmptyOrder`) live on the aggregate, not in a service or handler. The application service loads the aggregate, calls a method, and saves.

## What "small" means

- A single aggregate is loaded and saved in one transaction.
- If you need to update two aggregates in the same business operation, prefer eventual consistency (domain event + outbox) over a cross-aggregate transaction.
- Don't load the whole catalog into a `Catalog` aggregate. A product reference inside an order is a value object (`ProductID`), not a child entity.

## Clock injection

Don't call `time.Now()` inside the aggregate if you need to test it. Inject a `func() time.Time` (the **clock**) into the application service, which passes `now` into the aggregate. This keeps domain tests deterministic without a mocking framework.

```go
type Clock interface {
    Now() time.Time
}

type realClock struct{}

func (realClock) Now() time.Time { return time.Now() }

// In tests:
type fixedClock struct{ t time.Time }
func (f fixedClock) Now() time.Time { return f.t }
```

## Checklist

- [ ] Aggregate root is the only type held by reference outside the aggregate
- [ ] All state changes go through methods on the root
- [ ] Business rules raise domain errors, not boolean returns
- [ ] Constructor validates inputs and returns `(*Aggregate, error)`
- [ ] `time.Now()` and other non-deterministic calls are injected, not hard-coded
- [ ] Slices/maps returned by getters are defensive copies
- [ ] Aggregate size is small enough to load in a single transaction
