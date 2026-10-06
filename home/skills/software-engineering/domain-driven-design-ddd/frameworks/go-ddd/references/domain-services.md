# Domain Services

Location: `internal/<context>/domain/services/`

Domain services hold **pure business logic** that does not naturally belong to a single entity or value object — typically a policy or calculation that spans several aggregates. They do **not** orchestrate use cases and do **not** depend on repositories or transactions.

- **Interface first** (Go's structural typing makes this natural: a `*PricingPolicy` that has the right methods satisfies the port).
- **No infrastructure imports.** No `net/http`, no `pgx`, no `database/sql`, no logging frameworks — only stdlib and the domain itself.
- **No `*Service` naming for application ports.** The names `OrderCommandService` / `OrderQueryService` belong to the application layer. In the domain, use `*Policy`, `*Calculator`, `*Specification`, or a name from the ubiquitous language (`PricingPolicy`, `DiscountCalculator`, `ShippingEligibilityPolicy`).
- **Stateless.** Holds no state between invocations.
- **No repositories, no transactions.** If a service needs a repository, it is an application service, not a domain service.

## Example

```go
// File: internal/billing/domain/services/pricing_policy.go
package services

import (
    "github.com/acme/platform/billing/domain/model/aggregates"
    "github.com/acme/platform/billing/domain/model/valueobjects"
)

// PricingPolicy calculates the total price for an order, applying business
// rules that don't naturally live on a single entity.
type PricingPolicy interface {
    Apply(order *aggregates.Order, customer *aggregates.Customer) (valueobjects.Money, error)
}

// File: internal/billing/domain/services/standard_pricing_policy.go
package services

import "github.com/acme/platform/billing/domain/model/valueobjects"

type StandardPricingPolicy struct{}

func NewStandardPricingPolicy() StandardPricingPolicy { return StandardPricingPolicy{} }

func (StandardPricingPolicy) Apply(
    order *aggregates.Order,
    customer *aggregates.Customer,
) (valueobjects.Money, error) {
    // ... pure calculation, no I/O ...
}
```

The application service receives the policy via constructor injection (or instantiates it if it has no dependencies). The interfaces and infrastructure layers never see this type.

## What a domain service is NOT

- It is **not** an application service (those orchestrate use cases — see `application-services.md`).
- It is **not** a repository (those persist aggregates — see `repositories.md`).
- It is **not** a domain event handler (those consume events asynchronously, in `application/` or `infrastructure/`).
- It is **not** a `*CommandService` or `*QueryService`. Those are application-layer names.

## Checklist

- [ ] Defined in `domain/services/`
- [ ] No `net/http`, no driver, no framework imports
- [ ] No `*Service` naming — use `*Policy` / `*Calculator` / `*Specification`
- [ ] No repository or transaction dependencies
- [ ] Methods express business rules in the ubiquitous language
- [ ] Returns are domain types or built-in Go types
- [ ] Stateless
