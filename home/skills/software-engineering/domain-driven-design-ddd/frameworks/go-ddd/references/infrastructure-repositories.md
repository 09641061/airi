# Infrastructure Repositories

## 6. Infrastructure Repositories

**Locations:**

- **Repository contract (interface):** `[context-name]/domain/repositories/`
- **Repository implementation (adapter):** `[context-name]/infrastructure/persistence/postgres/repositories/`

**Mandatory rule:** the **domain defines the repository interface**, and **infrastructure implements it**. Application services receive the domain interface through constructor injection. Neither domain nor application imports the PostgreSQL adapter.

**Domain contract** — `domain/repositories/entity_repository.go`:

```go
package repositories

import (
    "context"

    "your.module/internal/[context-name]/domain/model/aggregates"
    "your.module/internal/[context-name]/domain/model/valueobjects"
)

type EntityRepository interface {
    Save(ctx context.Context, entity *aggregates.Entity) error
    FindByID(ctx context.Context, id valueobjects.EntityID) (*aggregates.Entity, error)
}
```

**Infrastructure adapter** — `infrastructure/persistence/postgres/repositories/entity_repository.go`:

```go
package repositories

import "github.com/jackc/pgx/v5/pgxpool"

type PostgresEntityRepository struct {
    pool *pgxpool.Pool
}

func NewPostgresEntityRepository(pool *pgxpool.Pool) *PostgresEntityRepository {
    return &PostgresEntityRepository{pool: pool}
}

// Implement the domain repository's Save and FindByID methods here.
// This adapter executes SQL (or sqlc) and maps rows to domain aggregates.
```

The adapter must implement the domain interface with the **same method signatures**. Once methods are implemented, add a compile-time assertion if useful:

```go
// In the infrastructure repository package:
// var _ domainrepositories.EntityRepository = (*PostgresEntityRepository)(nil)
```

- **Aggregate focus:** generally one repository interface per aggregate root, not per table.
- **Domain types:** use entities, aggregate roots, IDs, and Value Objects in contracts; no SQL rows, `pgx`, or `sqlc` types.
- **Persistence details:** SQL queries, transactions, error mapping, and row transformations belong to infrastructure.
- **Dependency direction:** `application → domain/repositories ← infrastructure adapter`; `bootstrap` connects them.

- [ ] Repository **interface is defined in `domain/repositories/`**.
- [ ] Concrete PostgreSQL repository is defined **only in infrastructure**.
- [ ] Infrastructure implements the domain interface.
- [ ] Application services depend only on the domain interface.
- [ ] Repository methods operate on aggregate roots and domain types.
- [ ] One repository per aggregate root by default.
- [ ] Parameterized SQL (or `sqlc`) is used; persistence errors and concurrency are handled.
- [ ] No database, Gin, or framework dependencies leak into domain or application.

---
