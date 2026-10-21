# Repository Contracts and Persistence Adapters

A Repository exposes the persistence operations required by a domain aggregate. The interface belongs to the domain; its concrete implementation belongs to the owning context's infrastructure. Persistence technology is selected per context and is not prescribed by DDD.

## Placement and contracts

- Domain contract: `[context-name]/domain/repositories/`.
- Concrete adapter: `[context-name]/infrastructure/persistence/[technology]/`.
- A repository persists/reconstructs an aggregate according to its domain contract. Do not add generic CRUD methods merely for symmetry.
- Multiple technologies may implement the same port only when they satisfy its consistency, absence, and query semantics.

Illustrative, non-compilable template until module path and domain types are replaced:

```go
package repositories

import (
    "context"
    "<module>/internal/<context-name>/domain/model/entities"
    "<module>/internal/<context-name>/domain/model/valueobjects"
)

type EntityRepository interface {
    Save(ctx context.Context, aggregate *entities.Entity) error
    FindByID(ctx context.Context, id valueobjects.EntityID) (*entities.Entity, error)
}
```

## Adapter responsibilities

- Name the implementation for its technology when useful, for example `[Technology]EntityRepository`.
- Keep SQL rows, ORM models, document schemas, tags, and storage mapping inside the adapter.
- Translate driver/storage errors to the domain/application contract. Define absence, conflicts, and optimistic-concurrency behavior explicitly; do not use sentinel values such as `0` for absence.
- Pass `context.Context` through I/O operations and honor cancellation/deadlines.
- Test the adapter against the actual selected persistence engine for mapping, constraints, concurrency, and engine-specific behavior.
- Coordinate transactions only where needed and supported by the actual engine; do not assume identical guarantees across technologies.

A shared infrastructure package may create a technical client/factory used by multiple contexts when there is genuine reuse. Aggregate repositories remain in their owning contexts; do not put them in `shared/` merely because contexts use the same database or client.

## Persistence checklist

- Repository interfaces are in `domain/repositories/`; implementations are under the owning context's `infrastructure/persistence/[technology]/`.
- No storage-specific type, annotation, or assumption leaks through the domain port.
- Aggregate consistency, absence, conflict, and concurrency semantics are documented.
- Integration/contract tests exercise the selected real engine; an in-memory fake does not prove production storage semantics.
- No database, ORM, migration tool, connection pool, or query generator is mandatory.
