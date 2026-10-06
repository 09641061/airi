# Interface (HTTP) Tests

Location: `internal/<context>/interfaces/rest/`

HTTP tests verify the **complete handler** end-to-end through `httptest`. They check routing, request parsing, status codes, response format, and error translation. They don't retest every domain rule.

## Stack

- `net/http/httptest` for in-process server testing
- `bytes.NewReader` / `strings.NewReader` for request bodies
- `httptest.NewRecorder` for capturing responses (or `httptest.NewServer` for full network round-trips)

## What to test

- Routing: the right handler runs for the right method + path
- Request parsing: valid bodies parse, malformed bodies are rejected with 400
- Validation: missing fields, wrong types, and out-of-range values are rejected
- Status codes: 200/201/204 for success, 400/404/409/422 for client errors, 500 for server errors
- Response body: shape, JSON keys, types
- Headers: `Content-Type`, `Location` for 201, correlation headers
- Error translation: domain sentinels map to the right HTTP status (see `ddd-go/references/domain-errors.md`)

## What NOT to test in the interface layer

- Domain rules — already covered by domain tests
- Persistence — covered by infrastructure tests
- Internal handler helpers — the test exercises the handler, not its callees

## Handler test

```go
// File: internal/order/interfaces/rest/order_handler_test.go
package rest_test

import (
    "bytes"
    "encoding/json"
    "io"
    "log/slog"
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/acme/platform/order/application"
    "github.com/acme/platform/order/interfaces/rest"
    "github.com/acme/platform/order/interfaces/rest/resources"
)

func newTestHandler(t *testing.T) http.Handler {
    t.Helper()
    repo := newFakeOrderRepository()
    clock := fixedClock{t: time.Now()}
    svc := application.NewOrderService(repo, clock)
    h := rest.NewOrderHandler(svc, slog.New(slog.NewTextHandler(io.Discard, nil)))
    return rest.NewRouter(h)
}

func TestOrderHandler_CreateOrder_Returns201(t *testing.T) {
    t.Parallel()
    handler := newTestHandler(t)

    body, _ := json.Marshal(resources.CreateOrderRequest{CustomerID: 42})
    req := httptest.NewRequest(http.MethodPost, "/orders", bytes.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    rec := httptest.NewRecorder()

    handler.ServeHTTP(rec, req)

    if rec.Code != http.StatusCreated {
        t.Fatalf("status = %d, want 201; body = %s", rec.Code, rec.Body.String())
    }
    if got := rec.Header().Get("Content-Type"); got != "application/json" {
        t.Fatalf("Content-Type = %q, want application/json", got)
    }

    var got resources.OrderResponse
    if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
        t.Fatalf("decode: %v", err)
    }
    if got.CustomerID != 42 {
        t.Fatalf("customer = %d, want 42", got.CustomerID)
    }
    if got.Status != "pending" {
        t.Fatalf("status = %q, want pending", got.Status)
    }
}
```

## Error path tests

```go
func TestOrderHandler_CreateOrder_InvalidBody_Returns400(t *testing.T) {
    t.Parallel()
    handler := newTestHandler(t)

    req := httptest.NewRequest(http.MethodPost, "/orders", bytes.NewReader([]byte(`not json`)))
    req.Header.Set("Content-Type", "application/json")
    rec := httptest.NewRecorder()
    handler.ServeHTTP(rec, req)

    if rec.Code != http.StatusBadRequest {
        t.Fatalf("status = %d, want 400", rec.Code)
    }
}

func TestOrderHandler_ConfirmOrder_NotFound_Returns404(t *testing.T) {
    t.Parallel()
    handler := newTestHandler(t)

    req := httptest.NewRequest(http.MethodPost, "/orders/999/confirm", nil)
    rec := httptest.NewRecorder()
    handler.ServeHTTP(rec, req)

    if rec.Code != http.StatusNotFound {
        t.Fatalf("status = %d, want 404", rec.Code)
    }

    var problem map[string]any
    if err := json.Unmarshal(rec.Body.Bytes(), &problem); err != nil {
        t.Fatalf("problem decode: %v", err)
    }
    if problem["type"] == nil {
        t.Fatalf("problem+json missing type field")
    }
}
```

## Sub-tests for status code matrix

When the same endpoint returns different status codes for different inputs, table-drive it.

```go
func TestOrderHandler_CreateOrder_StatusCodes(t *testing.T) {
    t.Parallel()
    tests := []struct {
        name       string
        body       string
        wantStatus int
    }{
        {"valid", `{"customerId":42}`, http.StatusCreated},
        {"missing customer", `{}`, http.StatusBadRequest},
        {"negative customer", `{"customerId":-1}`, http.StatusBadRequest},
        {"malformed json", `not json`, http.StatusBadRequest},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            handler := newTestHandler(t)
            req := httptest.NewRequest(http.MethodPost, "/orders", strings.NewReader(tt.body))
            req.Header.Set("Content-Type", "application/json")
            rec := httptest.NewRecorder()
            handler.ServeHTTP(rec, req)
            if rec.Code != tt.wantStatus {
                t.Fatalf("status = %d, want %d; body = %s", rec.Code, tt.wantStatus, rec.Body.String())
            }
        })
    }
}
```

## Provider-side ACL facade tests

The provider's facade is part of the interfaces layer too — it lives in `interfaces/acl/`. Test it with a fake `*CommandService` / `*QueryService`.

```go
type fakeCommandService struct {
    handleCreate func(ctx context.Context, cmd commands.CreateEntityCommand) (valueobjects.EntityID, error)
}

func (f *fakeCommandService) HandleCreateEntity(ctx context.Context, cmd commands.CreateEntityCommand) (valueobjects.EntityID, error) {
    return f.handleCreate(ctx, cmd)
}

func TestContextBFacade_CreateEntity_MapsError(t *testing.T) {
    t.Parallel()
    cmd := &fakeCommandService{
        handleCreate: func(context.Context, commands.CreateEntityCommand) (valueobjects.EntityID, error) {
            return valueobjects.EntityID{}, domain.ErrEntityAlreadyExists
        },
    }
    qry := &fakeQueryService{}
    f := acl.NewContextBFacade(cmd, qry)

    _, err := f.CreateEntity(context.Background(), "a", "b")
    if !errors.Is(err, domain.ErrEntityAlreadyExists) {
        t.Fatalf("want ErrEntityAlreadyExists, got %v", err)
    }
}
```

## Don't unit-test tiny helpers

If a handler helper exists only to format a response or set a header, test it through the handler, not in isolation. The end-to-end handler test is the contract; helper-only tests duplicate the contract without adding coverage.

## Checklist

- [ ] Test exercises the full HTTP handler via `httptest`
- [ ] Status codes for the success path and every documented error path
- [ ] Request parsing and validation tested
- [ ] Error response is `application/problem+json` (RFC 7807) for 4xx/5xx
- [ ] No domain-rule retests; domain tests already cover the underlying behavior
- [ ] Provider-side ACL facade tested with a fake command/query service
- [ ] `httptest.NewServer` is used only when the test needs a real network listener (rare)
