# Domain model: value objects and aggregate

An order accepts lines only while it is a draft and cannot be submitted empty. `SKU` is a value object because it normalizes and validates a domain identifier.

Constructors and behavior methods keep invalid states unreachable. Do not add setters for fields governed by invariants. Test value-object validation and aggregate transitions without a database.

## Domain errors and value objects

```go
// internal/orders/domain/order.go
package domain

import (
    "errors"
    "strings"
)

var (
    ErrInvalidOrderID         = errors.New("invalid order ID")
    ErrInvalidTenantID        = errors.New("invalid tenant ID")
    ErrOrderNotFound          = errors.New("order not found")
    ErrInvalidSKU             = errors.New("invalid SKU")
    ErrInvalidLine            = errors.New("quantity must be positive")
    ErrInvalidOrderState      = errors.New("invalid order state")
    ErrOrderNotDraft          = errors.New("order is not a draft")
    ErrEmptyOrder             = errors.New("cannot submit an empty order")
    ErrConcurrentModification = errors.New("order was modified concurrently")
)

type ID string
type TenantID string
type SKU string
type Status uint8

const (
    Draft Status = iota + 1
    Submitted
)

func ParseID(raw string) (ID, error) {
    raw = strings.TrimSpace(raw)
    if raw == "" {
        return "", ErrInvalidOrderID
    }
    return ID(raw), nil
}

func ParseTenantID(raw string) (TenantID, error) {
    raw = strings.TrimSpace(raw)
    if raw == "" {
        return "", ErrInvalidTenantID
    }
    return TenantID(raw), nil
}

func NewSKU(raw string) (SKU, error) {
    raw = strings.TrimSpace(raw)
    if raw == "" || len(raw) > 64 {
        return "", ErrInvalidSKU
    }
    return SKU(raw), nil
}

func (s SKU) String() string { return string(s) }

type Line struct {
    SKU      SKU
    Quantity int
}

type Order struct {
    id     ID
    status Status
    lines  []Line
}
```

## Aggregate root: constructor, transitions, reconstitution

```go
func NewOrder(rawID string) (*Order, error) {
    id, err := ParseID(rawID)
    if err != nil {
        return nil, err
    }
    return &Order{id: id, status: Draft}, nil
}

// Reconstitute persisted state through validation, not ORM setters.
func ReconstituteOrder(id ID, status Status, lines []Line) (*Order, error) {
    parsedID, err := ParseID(string(id))
    if err != nil {
        return nil, err
    }
    if status != Draft && status != Submitted {
        return nil, ErrInvalidOrderState
    }

    copied := make([]Line, 0, len(lines))
    for _, line := range lines {
        sku, err := NewSKU(line.SKU.String())
        if err != nil {
            return nil, err
        }
        if line.Quantity <= 0 {
            return nil, ErrInvalidLine
        }
        copied = append(copied, Line{SKU: sku, Quantity: line.Quantity})
    }
    if status == Submitted && len(copied) == 0 {
        return nil, ErrEmptyOrder
    }
    return &Order{id: parsedID, status: status, lines: copied}, nil
}

func (o *Order) AddLine(rawSKU string, quantity int) error {
    if o.status != Draft {
        return ErrOrderNotDraft
    }
    sku, err := NewSKU(rawSKU)
    if err != nil {
        return err
    }
    if quantity <= 0 {
        return ErrInvalidLine
    }
    o.lines = append(o.lines, Line{SKU: sku, Quantity: quantity})
    return nil
}

func (o *Order) Submit() error {
    if o.status != Draft {
        return ErrOrderNotDraft
    }
    if len(o.lines) == 0 {
        return ErrEmptyOrder
    }
    o.status = Submitted
    return nil
}

func (o *Order) ID() ID         { return o.id }
func (o *Order) Status() Status { return o.status }
func (o *Order) Lines() []Line  { return append([]Line(nil), o.lines...) }
```

## Rules to enforce

- Constructors return errors rather than zero-value invalid objects.
- Transitions are the only mutators; no exported setters on fields governed by invariants.
- `ReconstituteOrder` is the only path for state coming from persistence. It re-validates through the same constructors the aggregate uses.
- Domain errors are sentinel values (`var ErrX = errors.New(...)`), never HTTP codes. Transport mapping happens only at the adapter boundary.
- Test value objects and transitions without a database or Gin — pure functions over `*Order`.