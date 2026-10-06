# Anti-Corruption Layer (ACL) — Cross-Context Integration

Use this whenever a bounded context needs data or operations from another bounded context. **Never call another context's internals directly** — always go through an ACL facade.

> The facade exposes a public contract in `interfaces/acl/` (provider side) or `application/internal/outboundservices/acl/` (consumer side). Its implementation depends on the **application** command/query services, never on `domain/services/`. Domain services are pure policies/calculators and are not appropriate as consumers or producers of ACL facades.

## Step 1: Identify Communication Needs

```
1. What data does Context A need from Context B?
2. What operations must Context A perform against Context B?
```

## Step 2: Map Domain Models

```
Context A (Consumer) Model <-> Context B (Provider) Model
```

The mapping lives in the ACL — never leak the provider's domain model across the boundary.

## Step 3: Define the ACL contract

Keep the contract small and focused on the consumer's needs.

- Methods express what the consumer wants, not the provider's operations.
- Parameters and return types are simple Go types or value objects from the **consumer's** context, not the provider's.
- Failures are translated to the consumer's domain errors with `errors.Is`.

## Provider side — Context B

**Step 4: Define the facade interface in `interfaces/acl/`**

```go
// File: internal/<context-b>/interfaces/acl/context_b_facade.go
package acl

import "context"

// ContextBFacade is the public contract Context A uses to access Context B.
// Defined by the provider, consumed by the consumer.
type ContextBFacade interface {
    CreateEntity(ctx context.Context, param1, param2 string) (uint64, error)
    FindEntityIDByField(ctx context.Context, identifier string) (uint64, error)
}
```

**Step 5: Implement the facade in `application/acl/`**

```go
// File: internal/<context-b>/application/acl/context_b_facade_impl.go
package acl

import (
    "context"
    "errors"

    "github.com/acme/platform/<context-b>/application/commands"
    "github.com/acme/platform/<context-b>/application/queries"
    "github.com/acme/platform/<context-b>/application/services"
    "github.com/acme/platform/<context-b>/interfaces/acl"
)

type contextBFacadeImpl struct {
    commandService services.EntityCommandService
    queryService   services.EntityQueryService
}

func NewContextBFacade(
    commandService services.EntityCommandService,
    queryService services.EntityQueryService,
) acl.ContextBFacade {
    return &contextBFacadeImpl{
        commandService: commandService,
        queryService:   queryService,
    }
}

var _ acl.ContextBFacade = (*contextBFacadeImpl)(nil)

func (f *contextBFacadeImpl) CreateEntity(ctx context.Context, param1, param2 string) (uint64, error) {
    cmd, err := commands.NewCreateEntityCommand(param1, param2)
    if err != nil {
        return 0, err
    }
    id, err := f.commandService.HandleCreateEntity(ctx, cmd)
    if err != nil {
        return 0, err
    }
    return id.Value(), nil
}

func (f *contextBFacadeImpl) FindEntityIDByField(ctx context.Context, identifier string) (uint64, error) {
    query, err := queries.NewFindEntityByFieldQuery(identifier)
    if err != nil {
        return 0, err
    }
    entity, err := f.queryService.HandleFindEntityByField(ctx, query)
    if err != nil {
        return 0, err
    }
    if entity == nil {
        return 0, ErrEntityNotFound  // sentinel defined in this package
    }
    return entity.ID().Value(), nil
}

var ErrEntityNotFound = errors.New("entity not found in context B")
```

**Use typed sentinels, not magic `0` values.** Returning `(0, nil)` as "not found" is a Go anti-pattern: `0` is a valid ID for some entities, and the caller has to remember to special-case it.

## Consumer side — Context A

**Step 6: Define a value object in the consumer's domain for the foreign ID**

```go
// File: internal/<context-a>/domain/model/valueobjects/entity_id.go
package valueobjects

import "errors"

type EntityID struct {
    Value uint64 `json:"value" db:"entity_id"`
}

func NewEntityID(value uint64) (EntityID, error) {
    if value == 0 {
        return EntityID{}, errors.New("entity ID must be positive")
    }
    return EntityID{Value: value}, nil
}
```

The value object is owned by the consumer — it is not a re-export of the provider's type.

**Step 7: Implement the outbound ACL service**

```go
// File: internal/<context-a>/application/internal/outboundservices/acl/external_entity_service.go
package acl

import (
    "context"
    "errors"

    "github.com/acme/platform/<context-a>/domain/model/valueobjects"
    contextb "github.com/acme/platform/<context-b>/interfaces/acl"
)

// ExternalEntityService is the consumer-side ACL wrapper around ContextBFacade.
// It is the only type in Context A that knows Context B exists.
type ExternalEntityService struct {
    contextB contextb.ContextBFacade
}

func NewExternalEntityService(contextB contextb.ContextBFacade) *ExternalEntityService {
    return &ExternalEntityService{contextB: contextB}
}

func (s *ExternalEntityService) FetchEntityByField(ctx context.Context, field string) (*valueobjects.EntityID, error) {
    raw, err := s.contextB.FindEntityIDByField(ctx, field)
    if errors.Is(err, contextb.ErrEntityNotFound) {
        return nil, ErrEntityNotFound
    }
    if err != nil {
        return nil, err
    }
    return valueobjects.NewEntityID(raw)
}

func (s *ExternalEntityService) CreateEntity(ctx context.Context, param1, param2 string) (*valueobjects.EntityID, error) {
    raw, err := s.contextB.CreateEntity(ctx, param1, param2)
    if err != nil {
        return nil, err
    }
    return valueobjects.NewEntityID(raw)
}

var ErrEntityNotFound = errors.New("entity not found in external context")
```

**Step 8: Inject the ACL into the application service**

```go
// File: internal/<context-a>/application/internal/commandservices/consumer_entity_command_service_impl.go
package commandservices

import (
    "context"
    "errors"

    "github.com/acme/platform/<context-a>/application/commands"
    "github.com/acme/platform/<context-a>/application/internal/outboundservices/acl"
    "github.com/acme/platform/<context-a>/application/services"
    "github.com/acme/platform/<context-a>/domain/model/aggregates"
    "github.com/acme/platform/<context-a>/domain/repositories"
)

type consumerEntityCommandServiceImpl struct {
    repository            repositories.ConsumerEntityRepository
    externalEntityService *acl.ExternalEntityService
}

func NewConsumerEntityCommandService(
    repository repositories.ConsumerEntityRepository,
    externalEntityService *acl.ExternalEntityService,
) services.ConsumerEntityCommandService {
    return &consumerEntityCommandServiceImpl{
        repository:            repository,
        externalEntityService: externalEntityService,
    }
}

func (s *consumerEntityCommandServiceImpl) HandleCreateConsumerEntity(
    ctx context.Context,
    cmd commands.CreateConsumerEntityCommand,
) error {
    entityID, err := s.externalEntityService.FetchEntityByField(ctx, cmd.Field())
    if errors.Is(err, acl.ErrEntityNotFound) {
        entityID, err = s.externalEntityService.CreateEntity(ctx, cmd.Param1(), cmd.Param2())
        if err != nil {
            return err
        }
    } else if err != nil {
        return err
    }

    if exists, err := s.repository.ExistsByEntityID(ctx, *entityID); err != nil {
        return err
    } else if exists {
        return ErrDuplicateConsumerEntity
    }

    consumer, err := aggregates.NewConsumerEntity(*entityID)
    if err != nil {
        return err
    }
    return s.repository.Save(ctx, consumer)
}
```

## Common pitfalls to avoid

1. **Don't expose complex domain objects** — use simple types (`uint64`, `string`, value objects) in the ACL.
2. **Don't create circular dependencies** — Context A → Context B, never both ways.
3. **Don't use sentinel values** — `0` and `nil` are not "not found". Use typed sentinels and `errors.Is`.
4. **Don't skip error translation** — map provider errors to consumer-side sentinels; never let the provider's error type escape.
5. **Don't tighten coupling** — always go through the ACL interface, never direct internal calls.
6. **Don't forget compensation** — if Context B's call succeeds and Context A's persistence fails, you'll have an orphan in B. Either use a saga / compensating action or design the operation so the failure is recoverable.
7. **Don't inject concrete types** — the consumer depends on the ACL interface, not on a `*ConcreteBService`. That's what makes it mockable.
8. **Don't skip context propagation** — pass `ctx` through every ACL call so cancellations and deadlines work end to end.

## Checklist

- [ ] Facade interface defined in provider's `interfaces/acl/`
- [ ] Facade implementation depends on provider's **application** services, not on `domain/services/`
- [ ] No sentinel `0` / `nil` returns — use typed `ErrX` sentinels
- [ ] Consumer depends on the ACL interface, not on a concrete type
- [ ] Foreign IDs are wrapped in the consumer's own value object
- [ ] Errors from the provider are translated to consumer-side sentinels via `errors.Is`
- [ ] Compensating action / saga defined for multi-step cross-context operations
- [ ] `ctx` is propagated through every ACL call
