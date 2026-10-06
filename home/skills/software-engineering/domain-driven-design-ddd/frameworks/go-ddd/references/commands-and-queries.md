# Commands and Queries (optional)

The default case for an application service is one method per use case with an `Input` struct for parameters. Introduce explicit `*Command` and `*Query` types only when they improve clarity — for example:

- A single use case is dispatched from multiple transports (REST, gRPC, message queue) and you want a single validated carrier.
- The same command is replayed asynchronously (e.g. via the outbox) and must be serializable.
- The team prefers the "everything is a value object" style and wants symmetric naming across use cases.

Don't introduce commands and queries "because DDD examples use them". If the only place a `CreateUserCommand` exists is the call from the controller, an input struct is enough.

## Naming convention

- **Files end with `_command.go` / `_query.go`.**
- **Type names end with `Command` / `Query`**: `CreateUserCommand`, `FindUserByEmailQuery`.
- **Unexported fields with `Value()` getters** if you want true immutability at the field level. Or exported fields with private constructor and validation — same trade-off as value objects.
- **Constructors return `(T, error)`** and validate inputs.

## Example — Command

```go
// File: internal/order/application/commands/confirm_order_command.go
package commands

import (
    "errors"

    "github.com/acme/platform/order/domain/model/valueobjects"
)

type ConfirmOrderCommand struct {
    orderID valueobjects.OrderID
}

func NewConfirmOrderCommand(id uint64) (ConfirmOrderCommand, error) {
    orderID, err := valueobjects.NewOrderID(id)
    if err != nil {
        return ConfirmOrderCommand{}, err
    }
    return ConfirmOrderCommand{orderID: orderID}, nil
}

func (c ConfirmOrderCommand) OrderID() valueobjects.OrderID { return c.orderID }
```

## Example — Query

```go
// File: internal/order/application/queries/find_order_by_id_query.go
package queries

import "github.com/acme/platform/order/domain/model/valueobjects"

type FindOrderByIDQuery struct {
    orderID valueobjects.OrderID
}

func NewFindOrderByIDQuery(id uint64) (FindOrderByIDQuery, error) {
    orderID, err := valueobjects.NewOrderID(id)
    if err != nil {
        return FindOrderByIDQuery{}, err
    }
    return FindOrderByIDQuery{orderID: orderID}, nil
}

func (q FindOrderByIDQuery) OrderID() valueobjects.OrderID { return q.orderID }
```

## Service contract

When commands and queries are introduced, give the application service a named contract so the interfaces layer depends on an interface, not a concrete struct.

```go
// File: internal/order/application/order_service.go
package application

import (
    "context"

    "github.com/acme/platform/order/application/commands"
    "github.com/acme/platform/order/application/queries"
    "github.com/acme/platform/order/domain/model/aggregates"
    "github.com/acme/platform/order/domain/model/valueobjects"
)

type OrderCommandService interface {
    HandleCreateOrder(ctx context.Context, cmd commands.CreateOrderCommand) (valueobjects.OrderID, error)
    HandleConfirmOrder(ctx context.Context, cmd commands.ConfirmOrderCommand) error
}

type OrderQueryService interface {
    HandleFindOrderByID(ctx context.Context, query queries.FindOrderByIDQuery) (*aggregates.Order, error)
    HandleFindOrdersByCustomer(ctx context.Context, query queries.FindOrdersByCustomerQuery) ([]*aggregates.Order, error)
}
```

**Notice the method names** — every method is `Handle<Operation>`, not `Handle` + `HandleUpdate`. Without the operation suffix, Go cannot disambiguate and the compiler rejects the duplicate `Handle` definitions.

## When NOT to use commands/queries

- The use case is called from exactly one place and the input struct already documents it.
- The team is small and the extra type doesn't add value.
- The "command" is just a method call away — wrapping it in a struct is ceremony.

## Checklist

- [ ] Command/Query files end with `_command.go` / `_query.go`
- [ ] Constructors validate inputs and return `(T, error)`
- [ ] Service contract interface uses `Handle<Operation>` naming, never bare `Handle` + `HandleUpdate`
- [ ] Commands/Queries are immutable after construction
- [ ] No transport or driver import in the command/query files
