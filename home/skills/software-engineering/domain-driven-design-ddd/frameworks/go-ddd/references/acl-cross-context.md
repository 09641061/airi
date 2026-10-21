# Anti-Corruption Layer (ACL)

## 12. ACL Implementation

An **Anti-Corruption Layer (ACL)** lets one bounded context use another without sharing its internal domain model.

### Step 1: Identify Communication Needs

```text
1. What data does Context A need from Context B?
2. What operations must Context A perform against Context B?
```

### Step 2: Map Domain Models

```text
Context A (Consumer) Model <-> Context B (Provider) Model
```

Translate concepts and IDs rather than importing the provider's aggregates directly.

### Step 3: Define ACL Interface Contract

```text
1. Which methods does the facade expose?
2. Which parameters are required?
3. What are the return types?
4. How are errors and not-found cases represented?
```

Keep the contract **small, stable, and independent of Gin/PostgreSQL**.

#### Implementation in Provider Context (Context B)

### Step 4: Create ACL Facade Interface

**Location:** `[context-b]/interfaces/acl/context_facade.go`

```go
package acl

import "context"

type EntityID int64

type CreateEntityInput struct {
    Field string
}

type ContextFacade interface {
    CreateEntity(context.Context, CreateEntityInput) (EntityID, error)
    FindEntityIDByField(context.Context, string) (EntityID, bool, error)
}
```

The facade returns a contract type (`EntityID`), not a provider aggregate.

### Step 5: Implement ACL Facade

**Location:** `[context-b]/application/acl/context_facade.go`

```go
package acl

import (
    "context"

    provider "your.module/internal/[context-b]/interfaces/acl"
    "your.module/internal/[context-b]/domain/model/commands"
    "your.module/internal/[context-b]/domain/model/queries"
)

type Creator interface {
    Handle(context.Context, commands.CreateEntityCommand) (provider.EntityID, error)
}

type Finder interface {
    Handle(context.Context, queries.GetEntityByFieldQuery) (provider.EntityID, bool, error)
}

type ContextFacade struct {
    creator Creator
    finder  Finder
}

func NewContextFacade(c Creator, f Finder) *ContextFacade {
    return &ContextFacade{creator: c, finder: f}
}

func (f *ContextFacade) CreateEntity(
    ctx context.Context, input provider.CreateEntityInput,
) (provider.EntityID, error) {
    return f.creator.Handle(ctx, commands.CreateEntityCommand{Field: input.Field})
}

func (f *ContextFacade) FindEntityIDByField(
    ctx context.Context, field string,
) (provider.EntityID, bool, error) {
    return f.finder.Handle(ctx, queries.GetEntityByFieldQuery{Field: field})
}

var _ provider.ContextFacade = (*ContextFacade)(nil)
```

The implementation delegates to application services. It must not contain HTTP logic or access another context's repository.

#### Implementation in Consumer Context (Context A)

### Step 6: Create Value Objects in Consumer Context

**Location:** `[context-a]/domain/model/valueobjects/entity_id.go`

```go
package valueobjects

import "errors"

type EntityID struct{ value int64 }

func NewEntityID(value int64) (EntityID, error) {
    if value <= 0 {
        return EntityID{}, errors.New("invalid entity ID")
    }
    return EntityID{value: value}, nil
}

func (id EntityID) Value() int64 { return id.value }
```

Context A owns its own type. It need not reuse Context B's domain type.

### Step 7: Create External Service (ACL Layer)

**Location:** `[context-a]/application/outboundservices/acl/external_entity_service.go`

```go
package acl

import (
    "context"

    values "your.module/internal/[context-a]/domain/model/valueobjects"
    provider "your.module/internal/[context-b]/interfaces/acl"
)

type ExternalEntityService struct {
    facade provider.ContextFacade
}

func NewExternalEntityService(f provider.ContextFacade) *ExternalEntityService {
    return &ExternalEntityService{facade: f}
}

func (s *ExternalEntityService) FindEntityIDByField(
    ctx context.Context, field string,
) (values.EntityID, bool, error) {
    id, found, err := s.facade.FindEntityIDByField(ctx, field)
    if err != nil || !found {
        return values.EntityID{}, found, err
    }
    result, err := values.NewEntityID(int64(id))
    return result, err == nil, err
}

func (s *ExternalEntityService) CreateEntity(
    ctx context.Context, field string,
) (values.EntityID, error) {
    id, err := s.facade.CreateEntity(ctx, provider.CreateEntityInput{Field: field})
    if err != nil {
        return values.EntityID{}, err
    }
    return values.NewEntityID(int64(id))
}
```

`ProviderFacade` is the consumer's narrow dependency on the **published** facade from Context B. No direct use of the provider's domain, SQL types, or controllers.

#### Integration in Consumer Context

### Step 8: Update Command Services

**Location:** `[context-a]/application/commandservices/`

```text
Generic orchestration sequence:
1. Resolve the external ID through ExternalEntityService.
2. Apply Context A's business rules.
3. Create/update Context A's aggregate.
4. Persist through Context A's **domain repository interface** (implemented in infrastructure).
5. Return the result, or wrap and return an error.
```

**Concurrency and transactions:** a `find -> create` sequence needs a unique constraint or idempotent operation to avoid duplicates. Different bounded contexts are **not automatically part of the same transaction** even when running in one monolith.

**Common Pitfalls to Avoid:**

1. **Do not expose complex domain objects** — publish simple ACL contracts.
2. **Do not create circular dependencies** — dependency direction must be clear.
3. **Do not skip error translation** — distinguish not found, conflicts, and technical failures.
4. **Do not skip testing** — test failure and concurrency scenarios.
5. **Do not tightly couple contexts** — never call another context's internal repositories.
6. **Do not use sentinel values** — use `(value, found, error)` or typed errors rather than an undocumented `0`.

---
