# Gin adapter and dependency wiring

Use `httpapi` rather than package `http` to distinguish the adapter from `net/http`. Auth middleware should place a validated `domain.TenantID` in Gin's context; **never trust an arbitrary tenant header/body field**. Pass tenant explicitly through application and repository calls. `context.Context` is for cancellation/deadlines, not hidden business identifiers.

Map errors to stable public messages; never return `err.Error()` to clients. Document endpoints in OpenAPI 3.1.

## Handler with tenant middleware and error mapping

```go
// internal/orders/interfaces/httpapi/order_handler.go
package httpapi

import (
    "context"
    "errors"
    "net/http"

    "example.com/shop/internal/orders/domain"
    "github.com/gin-gonic/gin"
)

type OrderUseCases interface {
    CreateOrder(context.Context, domain.TenantID) (domain.ID, error)
    AddLine(context.Context, domain.TenantID, domain.ID, string, int) error
    SubmitOrder(context.Context, domain.TenantID, domain.ID) error
}

type OrderHandler struct{ orders OrderUseCases }

func NewOrderHandler(orders OrderUseCases) *OrderHandler { return &OrderHandler{orders: orders} }

func tenantFrom(c *gin.Context) (domain.TenantID, bool) {
    value, exists := c.Get("tenantID")
    tenant, ok := value.(domain.TenantID)
    return tenant, exists && ok
}

func (h *OrderHandler) Submit(c *gin.Context) {
    tenant, ok := tenantFrom(c)
    if !ok {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
        return
    }
    id, err := domain.ParseID(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid order ID"})
        return
    }
    if err := h.orders.SubmitOrder(c.Request.Context(), tenant, id); err != nil {
        writeOrderError(c, err)
        return
    }
    c.Status(http.StatusNoContent)
}

func writeOrderError(c *gin.Context, err error) {
    switch {
    case errors.Is(err, domain.ErrOrderNotFound):
        c.JSON(http.StatusNotFound, gin.H{"error": "order not found"})
    case errors.Is(err, domain.ErrInvalidSKU), errors.Is(err, domain.ErrInvalidLine):
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid order line"})
    case errors.Is(err, domain.ErrOrderNotDraft):
        c.JSON(http.StatusConflict, gin.H{"error": "only draft orders can be changed"})
    case errors.Is(err, domain.ErrEmptyOrder):
        c.JSON(http.StatusConflict, gin.H{"error": "an order needs a line before submission"})
    case errors.Is(err, domain.ErrConcurrentModification):
        c.JSON(http.StatusConflict, gin.H{"error": "order changed; reload and retry"})
    default:
        c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
    }
}
```

The `Create` and `AddLine` handlers bind their request resources and call the corresponding use cases in the same way. Map errors to stable public messages; never return `err.Error()` to clients. Document endpoints in OpenAPI 3.1.

## Dependency wiring (datastore-independent composition)

```go
// cmd/api/wiring.go — datastore-independent composition
package main

import (
    "example.com/shop/internal/orders/application"
    "example.com/shop/internal/orders/domain"
    "example.com/shop/internal/orders/interfaces/httpapi"
    "github.com/gin-gonic/gin"
)

func buildRouter(repository domain.OrderRepository, ids application.IDGenerator) *gin.Engine {
    service := application.NewOrderService(repository, ids)
    handler := httpapi.NewOrderHandler(service)

    router := gin.New()
    router.Use(gin.Recovery())
    // Install authenticated tenant middleware before registering routes.
    router.POST("/orders/:id/submit", handler.Submit)
    return router
}
```

Register the create/add-line handlers alongside submit in the runnable API.

## Rules to enforce

- Package name is `httpapi`, never `http` — keeps the adapter distinct from `net/http`.
- Tenant is read **only** from a context value placed by auth middleware. Headers, query params, and request bodies are never sources of tenant identity.
- Handlers are thin: parse, validate transport input, call the use case, map domain errors to status codes. No business logic in handlers.
- `writeOrderError` is the single place that maps domain errors to HTTP responses. Never call `c.JSON(... err.Error() ...)`.
- Composition in `cmd/api` accepts `domain.OrderRepository` and `application.IDGenerator` — neither Gin nor any driver type crosses into wiring.