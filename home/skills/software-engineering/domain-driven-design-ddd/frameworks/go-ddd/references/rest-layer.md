# REST Layer (Resources + Handlers)

Location: `internal/<context>/interfaces/rest/`

The interfaces layer is the only place that knows about HTTP. Handlers are thin; resources are transport DTOs; errors are translated to status codes at this boundary.

## Default: `net/http`

Go 1.22+ ships a powerful HTTP server in the standard library. Start there. Reach for `gin` / `echo` / `chi` only when you need a feature the stdlib doesn't provide (e.g. advanced middleware composition, structured routing for very large surfaces).

```go
mux := http.NewServeMux()
mux.HandleFunc("POST /orders", h.CreateOrder)
mux.HandleFunc("GET /orders/{id}", h.GetOrder)
mux.HandleFunc("POST /orders/{id}/confirm", h.ConfirmOrder)
```

The method + path pattern (`POST /orders`) is part of the standard library since Go 1.22. No router is required.

## Resources (DTOs)

Resources are transport-only structs. They are **not** the domain entity.

- **Files end with `_resource.go`.**
- **One resource per HTTP operation**: `CreateOrderRequest`, `OrderResponse`, `ConfirmOrderResponse` (or just `OrderResponse` when the bodies match).
- **JSON tags use `camelCase` (or the convention the API contract specifies).**
- **Validation tags from `github.com/go-playground/validator/v10`** are fine here — this is the transport layer.
- **No behavior, no business methods.** Resources are data.

```go
// File: internal/order/interfaces/rest/resources/order_resource.go
package resources

import "time"

type CreateOrderRequest struct {
    CustomerID uint64 `json:"customerId" validate:"required,gt=0"`
}

type OrderResponse struct {
    ID         uint64    `json:"id" example:"1"`
    CustomerID uint64    `json:"customerId" example:"42"`
    Status     string    `json:"status" example:"pending"`
    CreatedAt  time.Time `json:"createdAt" example:"2024-01-01T00:00:00Z"`
}
```

## Handlers

A handler does five things, in order:

1. Read the request (path params, query params, body).
2. Validate transport input (struct tags, additional checks).
3. Call the application service.
4. Translate domain errors to HTTP status codes.
5. Write the response.

Nothing else.

```go
// File: internal/order/interfaces/rest/handlers.go
package rest

import (
    "context"
    "encoding/json"
    "errors"
    "log/slog"
    "net/http"

    "github.com/acme/platform/order/application"
    "github.com/acme/platform/order/domain"
    "github.com/acme/platform/order/domain/model/valueobjects"
    "github.com/acme/platform/order/interfaces/rest/resources"
)

type OrderHandler struct {
    service *application.OrderService
    logger  *slog.Logger
}

func NewOrderHandler(service *application.OrderService, logger *slog.Logger) *OrderHandler {
    return &OrderHandler{service: service, logger: logger}
}

// CreateOrder godoc
// @Summary  Create a new order
// @Tags     orders
// @Accept   json
// @Produce  json
// @Param    request  body      resources.CreateOrderRequest  true  "Order creation request"
// @Success  201      {object}  resources.OrderResponse
// @Failure  400      {object}  ProblemDetails
// @Failure  409      {object}  ProblemDetails
// @Failure  500      {object}  ProblemDetails
// @Router   /orders  [post]
func (h *OrderHandler) CreateOrder(w http.ResponseWriter, r *http.Request) {
    var req resources.CreateOrderRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeProblem(w, http.StatusBadRequest, "invalid request body", err.Error())
        return
    }

    customerID, err := valueobjects.NewCustomerID(req.CustomerID)
    if err != nil {
        writeProblem(w, http.StatusBadRequest, "invalid customer id", err.Error())
        return
    }

    order, err := h.service.CreateOrder(r.Context(), application.CreateOrderInput{
        CustomerID: customerID,
    })
    if err != nil {
        writeProblem(w, http.StatusInternalServerError, "could not create order", err.Error())
        return
    }

    writeJSON(w, http.StatusCreated, toOrderResponse(order))
}
```

## Error translation

Keep the mapping centralized in one file. Use `errors.Is` against the domain sentinels (see `domain-errors.md`).

```go
// File: internal/order/interfaces/rest/errors.go
package rest

import (
    "errors"
    "net/http"

    "github.com/acme/platform/order/domain"
)

func httpStatusFor(err error) int {
    switch {
    case errors.Is(err, domain.ErrOrderNotFound):
        return http.StatusNotFound
    case errors.Is(err, domain.ErrOrderAlreadyExists):
        return http.StatusConflict
    case errors.Is(err, domain.ErrCannotConfirmOrder),
        errors.Is(err, domain.ErrOrderClosed):
        return http.StatusUnprocessableEntity
    case errors.Is(err, domain.ErrInvalidAmount),
        errors.Is(err, domain.ErrInvalidCustomer):
        return http.StatusBadRequest
    default:
        return http.StatusInternalServerError
    }
}
```

## Problem Details (RFC 7807 / 9457)

Return errors in the `application/problem+json` format. See the [http-api-design](../../../software-architecture/http-api-design/SKILL.md) skill for the full schema. The handler helper above is a starting point.

## Server hardening (minimum)

- `http.Server{ ReadHeaderTimeout: 5*time.Second, ReadTimeout: 10*time.Second, WriteTimeout: 30*time.Second }`
- `r.Body = http.MaxBytesReader(w, r.Body, maxBodyBytes)` to cap request bodies.
- Graceful shutdown via `signal.NotifyContext` and `srv.Shutdown(ctx)`.
- A recovery middleware that logs and returns 500 (don't leak panics as 200).

## Checklist

- [ ] Handler files end with `_handler.go` (or one `handlers.go` for the context)
- [ ] Resources end with `_resource.go`
- [ ] No business logic in handlers; the handler is a 5-step pipeline
- [ ] Domain errors are translated to HTTP status with `errors.Is`, in one central place
- [ ] Errors return RFC 7807 Problem Details (`application/problem+json`)
- [ ] OpenAPI annotations are present on every public endpoint
- [ ] `http.Server` timeouts and request body limits are configured
