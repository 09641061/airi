# Testing and Observability

## Layered testing strategy

A test is a "unit" only if it runs in milliseconds without external processes. Anything that boots a database, a message broker, or an HTTP server is an integration test.

| Layer | What to test | Tools | Constraints |
|-------|--------------|-------|-------------|
| `domain/` | Value object validation, entity invariants, aggregate business methods, domain services | Stdlib `testing` only | No DB, no driver, no HTTP, no logging framework that pulls in I/O |
| `application/` | Use case orchestration, error translation, transaction boundaries | Stdlib `testing` + hand-rolled fakes of the repository ports | No DB, no real HTTP, no real ACL facade |
| `infrastructure/persistence/` | SQL queries, mapping, transaction handling | Stdlib `testing` + testcontainers-go with PostgreSQL | Real SQL against a real DB; tag with `//go:build integration` |
| `infrastructure/messaging/` | Publisher, consumer, outbox relay | Stdlib `testing` + testcontainers-go with NATS / Kafka | Real broker; tag with `//go:build integration` |
| `interfaces/rest/` | Routing, request decoding, error → status mapping, response writing | Stdlib `testing` + `httptest` | In-process server; no external dependencies |
| `interfaces/acl/` (provider) | Facade implementation, error translation | Stdlib `testing` + fake `*CommandService` / `*QueryService` | No external dependencies |
| `application/outboundservices/acl/` (consumer) | External service mapping, error translation | Stdlib `testing` + fake ACL facade | No external dependencies |
| End-to-end | Happy paths that span multiple contexts | Testcontainers for everything | Slow; tag separately |

## Domain tests are pure

The domain layer has no I/O. Tests should reflect that.

```go
// File: internal/order/domain/model/aggregates/order_test.go
package aggregates_test

import (
    "testing"
    "time"

    "github.com/acme/platform/order/domain"
    "github.com/acme/platform/order/domain/model/aggregates"
    "github.com/acme/platform/order/domain/model/valueobjects"
)

func TestOrder_Confirm(t *testing.T) {
    t.Parallel()

    customerID, _ := valueobjects.NewCustomerID(42)
    order, err := aggregates.NewOrder(
        mustOrderID(t, 1),
        customerID,
        time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC),
    )
    if err != nil {
        t.Fatalf("new order: %v", err)
    }

    if err := order.Confirm(time.Date(2024, 1, 2, 0, 0, 0, 0, time.UTC)); err != nil {
        t.Fatalf("confirm: %v", err)
    }
    if order.Status() != aggregates.StatusConfirmed {
        t.Fatalf("status = %q, want confirmed", order.Status())
    }

    if err := order.Confirm(time.Date(2024, 1, 3, 0, 0, 0, 0, time.UTC)); !errIs(err, domain.ErrCannotConfirmOrder) {
        t.Fatalf("second confirm: want ErrCannotConfirmOrder, got %v", err)
    }
}

func mustOrderID(t *testing.T, v uint64) valueobjects.OrderID {
    t.Helper()
    id, err := valueobjects.NewOrderID(v)
    if err != nil {
        t.Fatalf("order id: %v", err)
    }
    return id
}

func errIs(err, target error) bool {
    for err != nil {
        if err == target {
            return true
        }
        type unwrapper interface{ Unwrap() error }
        if u, ok := err.(unwrapper); ok {
            err = u.Unwrap()
            continue
        }
        return false
    }
    return false
}
```

> Use `errors.Is` from the stdlib directly — the manual helper above is only here to show what `errors.Is` does. Don't use `testify` or `assert` libraries in domain tests; they pull in dependencies the domain shouldn't need.

## Application tests use fakes

Hand-roll a fake for each repository port in the test package. Don't use a mocking library.

```go
// File: internal/order/application/order_service_test.go
package application_test

import (
    "context"
    "testing"
    "time"

    "github.com/acme/platform/order/application"
    "github.com/acme/platform/order/domain"
    "github.com/acme/platform/order/domain/model/valueobjects"
)

type fakeOrderRepo struct {
    orders map[valueobjects.OrderID]*fakeOrder
}

func newFakeOrderRepo() *fakeOrderRepo {
    return &fakeOrderRepo{orders: map[valueobjects.OrderID]*fakeOrder{}}
}

func (f *fakeOrderRepo) Save(_ context.Context, o *fakeOrder) error {
    f.orders[o.ID()] = o
    return nil
}
func (f *fakeOrderRepo) FindByID(_ context.Context, id valueobjects.OrderID) (*fakeOrder, error) {
    o, ok := f.orders[id]
    if !ok {
        return nil, domain.ErrOrderNotFound
    }
    return o, nil
}

type fixedClock struct{ t time.Time }

func (f fixedClock) Now() time.Time { return f.t }

func TestOrderService_ConfirmOrder(t *testing.T) {
    t.Parallel()
    repo := newFakeOrderRepo()
    clock := fixedClock{t: time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)}
    svc := application.NewOrderService(repo, clock)

    // arrange: create an order first
    // ...
}
```

## Infrastructure tests use real databases

Mark with a build tag and run them in CI against a real PostgreSQL.

```go
//go:build integration

package persistence_test

import (
    "context"
    "testing"

    "github.com/acme/platform/order/domain/model/aggregates"
    "github.com/acme/platform/order/infrastructure/persistence"
    "github.com/testcontainers/testcontainers-go/modules/postgres"
)

func TestOrderRepository_SaveAndFind(t *testing.T) {
    ctx := context.Background()
    pgC, err := postgres.RunContainer(ctx, ...)
    if err != nil { t.Fatal(err) }
    t.Cleanup(func() { _ = pgC.Terminate(ctx) })

    pool, err := pgxpool.New(ctx, pgC.ConnectionString(ctx))
    if err != nil { t.Fatal(err) }
    defer pool.Close()

    // apply migrations, then exercise the repository.
}
```

Avoid `pgxmock`, `sqlmock`, and GORM mock mode — they exercise driver defaults, not your code. The repository adapter is the boundary under test.

## HTTP handler tests

Use `httptest` from the stdlib.

```go
func TestOrderHandler_CreateOrder(t *testing.T) {
    t.Parallel()
    svc := application.NewOrderService(newFakeOrderRepo(), fixedClock{time.Now()})
    h := rest.NewOrderHandler(svc, slog.Default())

    body := strings.NewReader(`{"customerId":42}`)
    req := httptest.NewRequest(http.MethodPost, "/orders", body)
    rr := httptest.NewRecorder()
    h.CreateOrder(rr, req)

    if rr.Code != http.StatusCreated {
        t.Fatalf("status = %d, want 201", rr.Code)
    }
    var got resources.OrderResponse
    if err := json.Unmarshal(rr.Body.Bytes(), &got); err != nil {
        t.Fatalf("decode: %v", err)
    }
    if got.CustomerID != 42 {
        t.Fatalf("customer = %d, want 42", got.CustomerID)
    }
}
```

## Observability

### Structured logging with `log/slog`

```go
logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
slog.SetDefault(logger)

slog.InfoContext(ctx, "order confirmed",
    "order_id", order.ID().Value(),
    "customer_id", order.CustomerID().Value(),
)
```

Log at the application and infrastructure boundaries. Don't inject loggers into domain entities — the domain stays pure.

### Correlation IDs

- Read the correlation ID from the inbound request header (`X-Request-ID`).
- Stash it in the `context.Context` (e.g. via `context.WithValue` or a typed key).
- Outbound calls (ACL, HTTP) propagate it as a header.
- Logging middleware extracts it and includes it in every log line.

### Metrics and tracing

- Prometheus client for metrics (latency histograms, error counters).
- OpenTelemetry SDK for distributed traces — instrument HTTP inbound/outbound, `pgx` queries, ACL calls.

## Checklist

- [ ] Domain tests are pure (no driver, no HTTP, no DB)
- [ ] Application tests use hand-rolled fakes, not mocking libraries
- [ ] Infrastructure tests use real databases via testcontainers, tagged `//go:build integration`
- [ ] HTTP handler tests use `httptest`
- [ ] No use of `pgxmock` / `sqlmock` / GORM mock mode
- [ ] `slog` is the only logging dependency
- [ ] Correlation ID is propagated through `context.Context` to every outbound call
- [ ] Metrics and traces instrument the application and infrastructure boundaries
