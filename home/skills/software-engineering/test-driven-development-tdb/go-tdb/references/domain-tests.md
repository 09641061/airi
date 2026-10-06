# Domain Tests

Location: `internal/<context>/domain/` (co-located with the production code)

Domain tests are the most important tests in a DDD system. They cover the business behavior the rest of the system depends on.

## What to test

- Value object validation (valid and invalid inputs)
- Aggregate business rules and invariants
- State transitions
- Domain errors (sentinels, with `errors.Is`)
- Domain services (pure policies and calculations)

## What NOT to put in domain tests

- Database access (no `*pgxpool.Pool`, no `database/sql`, no GORM)
- HTTP (no `net/http`, no Gin, no Echo)
- Mocks (no mocking libraries, no fake repositories)
- Network or filesystem
- Logging frameworks that touch I/O
- `time.Now()` for non-deterministic behavior — inject a clock

Domain tests should be **fast** (sub-millisecond) and **isolated** (no external processes).

## Value objects

Every validation in the constructor gets a test.

```go
// File: internal/order/domain/model/valueobjects/money_test.go
package valueobjects_test

import (
    "testing"

    "github.com/acme/platform/order/domain/model/valueobjects"
)

func TestNewMoney(t *testing.T) {
    t.Parallel()
    tests := []struct {
        name     string
        cents    int64
        currency string
        wantErr  bool
    }{
        {name: "valid amount", cents: 100, currency: "USD"},
        {name: "valid zero amount", cents: 0, currency: "USD"},
        {name: "negative amount rejected", cents: -1, currency: "USD", wantErr: true},
        {name: "missing currency rejected", cents: 100, currency: "", wantErr: true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            _, err := valueobjects.NewMoney(tt.cents, tt.currency)

            if tt.wantErr && err == nil {
                t.Fatal("expected error, got nil")
            }
            if !tt.wantErr && err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
        })
    }
}
```

Use table-driven tests when the same behavior has several cases. Don't force every test into a table — if a test has a one-off setup that doesn't read well as a row, write it out.

## Aggregates and entities

Tests assert observable behavior, not internal state.

```go
// File: internal/order/domain/model/aggregates/order_test.go
package aggregates_test

import (
    "errors"
    "testing"
    "time"

    "github.com/acme/platform/order/domain"
    "github.com/acme/platform/order/domain/model/aggregates"
    "github.com/acme/platform/order/domain/model/valueobjects"
)

func newPendingOrder(t *testing.T) *aggregates.Order {
    t.Helper()
    customerID, err := valueobjects.NewCustomerID(42)
    if err != nil {
        t.Fatalf("customer id: %v", err)
    }
    orderID, err := valueobjects.NewOrderID(1)
    if err != nil {
        t.Fatalf("order id: %v", err)
    }
    order, err := aggregates.NewOrder(orderID, customerID, fixedTime())
    if err != nil {
        t.Fatalf("new order: %v", err)
    }
    return order
}

func fixedTime() time.Time {
    return time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
}

func TestOrderConfirm(t *testing.T) {
    t.Parallel()
    order := newPendingOrder(t)

    if err := order.Confirm(fixedTime()); err != nil {
        t.Fatalf("confirm: %v", err)
    }
    if order.Status() != aggregates.StatusConfirmed {
        t.Fatalf("status = %q, want %q", order.Status(), aggregates.StatusConfirmed)
    }
}

func TestConfirmedOrderCannotBeConfirmedAgain(t *testing.T) {
    t.Parallel()
    order := newPendingOrder(t)
    if err := order.Confirm(fixedTime()); err != nil {
        t.Fatalf("first confirm: %v", err)
    }

    err := order.Confirm(fixedTime())
    if !errors.Is(err, domain.ErrCannotConfirmOrder) {
        t.Fatalf("second confirm: want ErrCannotConfirmOrder, got %v", err)
    }
}
```

## Domain errors

Use `errors.Is` against sentinel errors. Don't compare error strings.

```go
err := order.Confirm(fixedTime())
if !errors.Is(err, domain.ErrCannotConfirmOrder) {
    t.Fatalf("expected ErrCannotConfirmOrder, got %v", err)
}
```

When the error is wrapped with `fmt.Errorf("...: %w", err)`, `errors.Is` still walks the chain. Test through the wrapped error to make sure wrapping doesn't break consumer code.

## Domain services

Domain services are pure — they have no dependencies, no I/O. Tests are straightforward: assert the output for a given input.

```go
func TestStandardPricingPolicy_AppliesVolumeDiscount(t *testing.T) {
    t.Parallel()
    policy := services.NewStandardPricingPolicy()

    // arrange: order with 10 items, customer with tier "gold"
    // act:     policy.Apply(order, customer)
    // assert:  total reflects the discount
}
```

## Time injection

Don't call `time.Now()` inside the aggregate if a business rule depends on it. Inject a `func() time.Time` (or a `Clock` interface) into the application service, which passes `now` into the aggregate.

```go
// Production wiring
type realClock struct{}
func (realClock) Now() time.Time { return time.Now() }

// Test wiring
type fixedClock struct{ t time.Time }
func (f fixedClock) Now() time.Time { return f.t }
```

Only abstract time when a test or rule actually depends on it. Don't introduce a clock "just in case" — it's an unnecessary indirection.

## Checklist

- [ ] Test file lives next to the production file
- [ ] Test package is `<thing>_test` (external) when possible
- [ ] Test name describes the business behavior, not the method
- [ ] No database, no HTTP, no mocks in domain tests
- [ ] `t.Parallel()` is called for tests that don't share state
- [ ] Table-driven tests are used when the same behavior has several cases
- [ ] `errors.Is` is used for sentinel errors
- [ ] Time is injected, not hard-coded with `time.Now()`
- [ ] Domain tests run in milliseconds on a developer laptop
