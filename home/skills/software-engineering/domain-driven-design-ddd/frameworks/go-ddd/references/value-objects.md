# Value Objects

Location: `internal/<context>/domain/model/valueobjects/`

- **Structs with validation in the constructor.** Value objects are immutable.
- **No framework, driver, or transport imports.** Only `errors`, `fmt`, `time`, and similar stdlib.
- **Decide your field-visibility model up front** (see Core rule 6 in `SKILL.md`):
  - **Exported fields with private constructor** — works directly with `encoding/json`, `pgx`, GORM, `sqlc`.
  - **Unexported fields with `Value()` getter** — requires a separate infrastructure-side persistence model and explicit mapper.
- **Don't create value objects for every primitive.** Create them when they protect a business rule, add semantic meaning, or remove ambiguity at the type level (`OrderID` vs `uint64`).

## Example — exported fields (default for IDs, money, ranges)

```go
// File: internal/order/domain/model/valueobjects/order_id.go
package valueobjects

import (
    "errors"
    "fmt"
)

type OrderID struct {
    Value uint64 `json:"value" db:"order_id"`
}

func NewOrderID(value uint64) (OrderID, error) {
    if value == 0 {
        return OrderID{}, errors.New("order ID must be positive")
    }
    return OrderID{Value: value}, nil
}

func (o OrderID) String() string {
    return fmt.Sprintf("ord_%d", o.Value)
}
```

The struct is immutable in practice because the only constructor validates. `json` and `db` tags on the exported field work for both `encoding/json` and `pgx`/`sqlx`/`sqlc` scan targets.

## Example — unexported fields with getter (use only when you need a true invariant boundary)

```go
// File: internal/order/domain/model/valueobjects/money.go
package valueobjects

import "errors"

type Money struct {
    cents    int64
    currency string
}

func NewMoney(cents int64, currency string) (Money, error) {
    if cents < 0 {
        return Money{}, ErrInvalidAmount
    }
    if currency == "" {
        return Money{}, ErrCurrencyRequired
    }
    return Money{cents: cents, currency: currency}, nil
}

func (m Money) Cents() int64    { return m.cents }
func (m Money) Currency() string { return m.currency }
```

> **Persistence side (infrastructure, NOT shown in the domain file):** because `encoding/json` and SQL drivers ignore unexported fields, this value object needs a JPA-style companion type in `infrastructure/persistence/models/money_model.go` and an explicit mapper. The mapper lives in `infrastructure/persistence/mappers/`, never in the domain.

## Checklist

- [ ] Value object is a struct, not a primitive alias
- [ ] Constructor validates inputs and returns `(T, error)`
- [ ] No framework/driver/transport import in the domain file
- [ ] Field-visibility model is consistent across the context (don't mix exported and unexported within the same aggregate)
- [ ] JSON/DB tags appear only on the persistence-side model when the value object uses unexported fields
- [ ] `String()` defined for IDs and other types that need stable textual representation
