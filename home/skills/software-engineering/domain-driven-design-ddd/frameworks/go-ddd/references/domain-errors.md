# Domain Errors

Location: `internal/<context>/domain/errors.go` (or split by aggregate if the context has many)

Domain errors describe business problems in the ubiquitous language. The transport layer translates them; the domain does not know HTTP, gRPC, or any driver.

- **Use `errors.New` or `fmt.Errorf` for typed values.** Sentinel errors are exposed as package-level `var ErrX = errors.New("...")`.
- **Use `errors.Is(err, domain.ErrX)` at the transport boundary to map a domain error to a status code.** Never use string matching.
- **No HTTP codes, no SQL state codes, no framework types in the domain.** `ErrHTTP404`, `ErrPostgresFailure`, and similar are forbidden in the domain.
- **Wrap with context when crossing layers.** Use `fmt.Errorf("loading order %s: %w", id, err)` so `errors.Is` still works.

## Example

```go
// File: internal/order/domain/errors.go
package domain

import "errors"

var (
    ErrOrderNotFound        = errors.New("order not found")
    ErrOrderAlreadyExists   = errors.New("order already exists")
    ErrCannotConfirmOrder   = errors.New("order cannot be confirmed in its current state")
    ErrOrderClosed          = errors.New("order is closed")
    ErrInvalidAmount        = errors.New("amount must be positive")
    ErrCurrencyRequired     = errors.New("currency is required")
)
```

## Translation at the transport boundary

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
        errors.Is(err, domain.ErrCurrencyRequired):
        return http.StatusBadRequest
    default:
        return http.StatusInternalServerError
    }
}
```

The domain never imports `net/http`. The transport never invents new error names — it only maps the domain's sentinels.

## Checklist

- [ ] All domain errors are sentinel `var ErrX = errors.New(...)` or wrapped with `fmt.Errorf("%w", err)`
- [ ] No HTTP, gRPC, or driver-specific error type in the domain
- [ ] The transport layer maps errors with `errors.Is`, never with string equality
- [ ] Wrapping is done with `fmt.Errorf("...: %w", err)` so the chain is preserved
- [ ] Errors are named after business facts, not technical failures (`ErrCannotConfirmOrder`, not `ErrInvalidStateTransition`)
