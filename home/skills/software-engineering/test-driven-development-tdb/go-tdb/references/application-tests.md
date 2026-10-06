# Application Tests

Location: `internal/<context>/application/`

Application tests verify use-case orchestration. They load an aggregate, call a domain method, persist the result, and translate errors. They don't re-test the domain rules — those have their own tests.

## What to test

- Use case orchestration: load → call domain method → save
- Error propagation: domain errors bubble up unchanged
- External capability coordination (ACL facades)
- Transaction boundaries (if the use case opens a transaction)
- Domain events raised by the aggregate reach the publisher

## What NOT to test in the application layer

- Business rules — those live on the aggregate and are covered by domain tests
- HTTP transport — covered by interface tests
- SQL — covered by infrastructure integration tests
- The repository port itself — that's a Go interface, not testable in isolation

## The repository fake

Hand-roll a fake that implements the port. The fake lives in the test package, not in production code.

```go
// File: internal/order/application/order_service_test.go
package application_test

import (
    "context"
    "testing"

    "github.com/acme/platform/order/domain"
    "github.com/acme/platform/order/domain/model/aggregates"
    "github.com/acme/platform/order/domain/model/valueobjects"
)

type fakeOrderRepository struct {
    orders  map[valueobjects.OrderID]*aggregates.Order
    saves   int
    findErr error
    saveErr error
}

func newFakeOrderRepository() *fakeOrderRepository {
    return &fakeOrderRepository{orders: map[valueobjects.OrderID]*aggregates.Order{}}
}

func (f *fakeOrderRepository) FindByID(_ context.Context, id valueobjects.OrderID) (*aggregates.Order, error) {
    if f.findErr != nil {
        return nil, f.findErr
    }
    o, ok := f.orders[id]
    if !ok {
        return nil, domain.ErrOrderNotFound
    }
    return o, nil
}

func (f *fakeOrderRepository) Save(_ context.Context, o *aggregates.Order) error {
    if f.saveErr != nil {
        return f.saveErr
    }
    f.orders[o.ID()] = o
    f.saves++
    return nil
}
```

Keep fakes small. They only need to support the assertions the test makes — not every method on the port.

## The service test

```go
type fixedClock struct{ t time.Time }

func (f fixedClock) Now() time.Time { return f.t }

func TestOrderService_ConfirmOrder_Persists(t *testing.T) {
    t.Parallel()
    repo := newFakeOrderRepository()
    clock := fixedClock{t: time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)}
    svc := application.NewOrderService(repo, clock)

    pending := seedPendingOrder(t, repo)

    if err := svc.ConfirmOrder(context.Background(), pending.ID()); err != nil {
        t.Fatalf("confirm: %v", err)
    }

    got, err := repo.FindByID(context.Background(), pending.ID())
    if err != nil {
        t.Fatalf("find: %v", err)
    }
    if got.Status() != aggregates.StatusConfirmed {
        t.Fatalf("status = %q, want confirmed", got.Status())
    }
    if repo.saves != 1 {
        t.Fatalf("saves = %d, want 1", repo.saves)
    }
}

func TestOrderService_ConfirmOrder_NotFound(t *testing.T) {
    t.Parallel()
    repo := newFakeOrderRepository()
    clock := fixedClock{t: time.Now()}
    svc := application.NewOrderService(repo, clock)

    missing, _ := valueobjects.NewOrderID(999)

    err := svc.ConfirmOrder(context.Background(), missing)
    if !errors.Is(err, domain.ErrOrderNotFound) {
        t.Fatalf("want ErrOrderNotFound, got %v", err)
    }
    if repo.saves != 0 {
        t.Fatalf("saves = %d, want 0 (no save on not found)", repo.saves)
    }
}

func TestOrderService_ConfirmOrder_DomainRuleFailureDoesNotSave(t *testing.T) {
    t.Parallel()
    repo := newFakeOrderRepository()
    clock := fixedClock{t: time.Now()}
    svc := application.NewOrderService(repo, clock)

    confirmed := seedOrderWithStatus(t, repo, aggregates.StatusConfirmed)

    err := svc.ConfirmOrder(context.Background(), confirmed.ID())
    if !errors.Is(err, domain.ErrCannotConfirmOrder) {
        t.Fatalf("want ErrCannotConfirmOrder, got %v", err)
    }
    if repo.saves != 0 {
        t.Fatalf("saves = %d, want 0 (no save on rule violation)", repo.saves)
    }
}
```

The "**does not save on rule violation**" assertion is the most important one. It's the test that proves the application service is a coordinator and not a decision-maker. If a future refactor moves the rule into the service and starts saving before checking, the test fails.

## ACL facades

Test the ACL service the same way — with a fake of the provider-side facade interface.

```go
type fakeContextBFacade struct {
    createFn  func(ctx context.Context, a, b string) (uint64, error)
    findFn    func(ctx context.Context, field string) (uint64, error)
}

func (f *fakeContextBFacade) CreateEntity(ctx context.Context, a, b string) (uint64, error) {
    return f.createFn(ctx, a, b)
}

func (f *fakeContextBFacade) FindEntityIDByField(ctx context.Context, field string) (uint64, error) {
    return f.findFn(ctx, field)
}

func TestExternalEntityService_FetchEntityByField_NotFound(t *testing.T) {
    t.Parallel()
    facade := &fakeContextBFacade{
        findFn: func(context.Context, string) (uint64, error) { return 0, contextb.ErrEntityNotFound },
    }
    svc := acl.NewExternalEntityService(facade)

    _, err := svc.FetchEntityByField(context.Background(), "missing")
    if !errors.Is(err, acl.ErrEntityNotFound) {
        t.Fatalf("want ErrEntityNotFound, got %v", err)
    }
}
```

The provider-side facade implementation gets its own test (see [interfaces-tests.md](interfaces-tests.md#provider-side-facade)) — the same way the application service does. Don't test the facade through the consumer's ACL; that's two layers of indirection.

## Transactions

If the application service uses a `UnitOfWork` port, the test should:

- Use a fake `UnitOfWork` that runs the function in-memory.
- Assert that the function is called when the use case runs.
- Assert that errors inside the function bubble up unchanged.

```go
type fakeUow struct {
    called bool
    err    error
}

func (f *fakeUow) WithinTx(ctx context.Context, fn func(ctx context.Context) error) error {
    f.called = true
    if f.err != nil {
        return f.err
    }
    return fn(ctx)
}
```

## Checklist

- [ ] Repository fake lives in the test package, not in production
- [ ] Fake supports only the assertions the test makes
- [ ] Test asserts that the rule failure does not call `Save`
- [ ] Test asserts that not-found does not call `Save`
- [ ] ACL services are tested with a fake facade, not a real provider
- [ ] No mocking framework (`gomock`, `mockery`, `testify/mock`)
- [ ] `t.Parallel()` is called for tests that don't share state
