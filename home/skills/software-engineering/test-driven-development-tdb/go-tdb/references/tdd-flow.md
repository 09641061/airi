# TDD Flow: Inside-Out by Layer

For a new feature, implement from the domain outward. Each layer's tests drive the layer below, in RED → GREEN → REFACTOR cycles.

```text
DOMAIN
  ↓
APPLICATION
  ↓
INFRASTRUCTURE
  ↓
INTERFACES
```

This keeps business behavior driving the implementation. If the domain tests are wrong, every layer above is wrong; if the domain tests are right, the higher layers are mostly orchestration and translation.

## Example: Confirm an Order

### Step 1 — Domain (RED)

```go
// File: internal/order/domain/model/aggregates/order_test.go
package aggregates_test

import (
    "testing"

    "github.com/acme/platform/order/domain/model/aggregates"
    "github.com/acme/platform/order/domain/model/valueobjects"
)

func newPendingOrder(t *testing.T) *aggregates.Order {
    t.Helper()
    customerID, err := valueobjects.NewCustomerID(42)
    if err != nil {
        t.Fatalf("customer id: %v", err)
    }
    id, err := valueobjects.NewOrderID(1)
    if err != nil {
        t.Fatalf("order id: %v", err)
    }
    order, err := aggregates.NewOrder(id, customerID, fixedTime())
    if err != nil {
        t.Fatalf("new order: %v", err)
    }
    return order
}

func fixedTime() time.Time {
    return time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
}
```

```go
func TestOrderConfirm(t *testing.T) {
    t.Parallel()
    order := newPendingOrder(t)

    if err := order.Confirm(fixedTime()); err != nil {
        t.Fatalf("confirm: %v", err)
    }
    if order.Status() != aggregates.StatusConfirmed {
        t.Fatalf("status = %q, want confirmed", order.Status())
    }
}
```

Run: fails because `Confirm` doesn't exist yet. **RED.**

### Step 2 — Domain (GREEN)

Add the minimum `Confirm` method to make the test pass. No extras, no optimization. **GREEN.**

### Step 3 — Domain (REFACTOR + RED for second behavior)

```go
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

Add the check, refactor the test helper, ensure both tests pass. **GREEN → REFACTOR.**

### Step 4 — Application (RED)

Drive the use case from the application service. The repository is a fake.

```go
func TestOrderService_ConfirmOrder_PersistsChange(t *testing.T) {
    t.Parallel()
    repo := newFakeOrderRepository()
    clock := fixedClock{t: fixedTime()}
    svc := application.NewOrderService(repo, clock)

    order := seedPendingOrder(t, repo)

    if err := svc.ConfirmOrder(context.Background(), order.ID()); err != nil {
        t.Fatalf("confirm: %v", err)
    }
    if !repo.saved[id] {
        t.Fatalf("expected order %s to be saved", id)
    }
}
```

### Step 5 — Application (GREEN)

Implement the orchestration. No business rules; the aggregate enforces them.

### Step 6 — Infrastructure (RED, integration)

```go
//go:build integration

func TestOrderRepository_SaveAndFind(t *testing.T) {
    // real PostgreSQL via testcontainers; tag with //go:build integration
}
```

### Step 7 — Interfaces (RED)

```go
func TestOrderHandler_ConfirmOrder_Returns200(t *testing.T) {
    t.Parallel()
    // arrange: handler wired with the application service and a fake repo
    // act:     httptest.NewRequest POST /orders/{id}/confirm
    // assert:  status 200, body matches the response shape
}
```

### Step 8 — Update OpenAPI

Add the new endpoint to `openapi/openapi.yaml`. The OpenAPI contract is part of the definition of done.

## Anti-patterns in the flow

- **Outside-in TDD for DDD.** Starting with the HTTP handler means you have to design the wire format before the domain. You end up constraining the model to the transport. Start inside.
- **Skipping the domain step.** The application service should not contain business rules. If you find yourself adding `if order.Status == "pending"` in the service, you skipped the domain test.
- **Merging the application and domain tests.** They are not the same. The domain test exercises the aggregate directly; the application test exercises orchestration with fakes for the ports. Don't try to do both in one test.
- **Writing the integration test before the unit test.** Integration tests are slower and harder to debug. Get the unit tests green first; use integration tests to verify the adapter, not the design.

## Definition of done for a feature

```text
[ ] Domain test for the new behavior
[ ] Domain test for the failure path (sentinel error returned)
[ ] Application test for the orchestration
[ ] Integration test for the persistence adapter
[ ] HTTP test for the new endpoint
[ ] OpenAPI updated
[ ] go test ./... passes
[ ] go test -race ./... passes
[ ] No new mocking framework, no new interface invented for tests
```
