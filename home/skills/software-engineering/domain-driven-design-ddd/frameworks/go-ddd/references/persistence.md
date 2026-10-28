# Repository Ports and Persistence Adapters

A Repository exposes the persistence operations required by an aggregate's model. In Go the interface is a **consumer-side contract**: the consumer declares the small set of operations it needs and the adapter satisfies it implicitly — there is no `implements` clause and no base interface to extend.

## Placement and contracts

- Port: the package that consumes it, typically `[context-name]/application/`.
- Adapter: `[context-name]/infrastructure/persistence/[technology]/`.
- When domain behavior itself needs a collaborator (an aggregate that must load a child collection), the domain package declares its own narrow interface — the domain is then the consumer, and the same rule applies.
- A repository persists/reconstructs an aggregate according to its port. Do not add generic CRUD methods merely for symmetry, and do not add a repository for an entity without invariants of its own.
- Multiple technologies may implement the same port only when they satisfy its consistency, absence, and query semantics.

```go
// internal/[context-name]/application/ports.go
package application

import (
    "context"
    "<module>/internal/<context-name>/domain"
)

// CourseRepository is the port the use cases need. The concrete adapter in
// infrastructure/persistence/[technology] satisfies it implicitly.
type CourseRepository interface {
    Save(ctx context.Context, course *domain.Course) error
    FindByID(ctx context.Context, id domain.CourseID) (*domain.Course, error)
}
```

The example is a template until its module path and domain types are replaced.

## Adapter rules

```text
internal/[context-name]/infrastructure/persistence/[technology]/
    course_repository.go
```

- Name the implementation for its technology when useful, for example `PostgresCourseRepository`. The adapter returns concrete types, not interfaces.
- Keep SQL rows, ORM models, document schemas, tags, and storage mapping inside the adapter.
- Translate driver/storage errors to the port's contract. Define absence (`ErrCourseNotFound`), conflicts, and optimistic-concurrency behavior explicitly; never use sentinel values such as `0` for absence.
- Pass `context.Context` through I/O operations and honor cancellation and deadlines.
- Test the adapter against the actual selected persistence engine for mapping, constraints, concurrency, and engine-specific behavior.
- A shared infrastructure package may create a technical client/factory used by multiple contexts when there is genuine reuse. Aggregate repositories remain in their owning contexts; do not put them in `shared/` merely because contexts use the same database or client.

## Transactions and Unit of Work

Transactions are a technical guarantee of a specific storage engine, not a domain concept. Keep them in the adapter and out of the use case.

- **Do not pass `*sql.Tx` (or any engine transaction handle) into application logic.** Use cases call ports; adapters decide how a write is made atomic.
- **Default — the adapter owns the transaction:** the adapter loads the aggregate, applies the change, and commits or rolls back within one call. A relational implementation typically does this with `SELECT ... FOR UPDATE` inside a transaction.
- **When two repositories must share one transaction,** expose a small transaction-provider port to the application layer and let the adapter build transaction-bound repositories. Keep the engine type behind the port.
- **Do not assume transaction semantics exist everywhere:** a document or key-value store may not offer multi-document atomicity. State the guarantee the use case actually relies on.

```go
// The application layer sees a port, never a transaction handle.
type TxManager interface {
    Transact(ctx context.Context, fn func(ctx context.Context) error) error
}
```

**Checklist (transactions)**

- [ ] No engine transaction type appears in application or domain code.
- [ ] The atomicity guarantee of each write is explicit.
- [ ] Multi-repository transactions use a narrow provider port, not a shared engine handle.
- [ ] Storage engines without transactional guarantees are not given SQL semantics by assumption.

Persistence technology is selected per context and is not prescribed by DDD: no database, ORM, migration tool, connection pool, or query generator is mandatory, and an in-memory fake does not prove production storage semantics.

## Mapping and the persistence representation

The persistence shape is a separate type that lives inside the adapter, never a struct tag or an annotation on the domain type. The mapping functions are the only place where both shapes meet — the Go equivalent of a persistence assembler.

```go
// internal/[context-name]/infrastructure/persistence/postgres/course_repository.go
package postgres

// courseRow is the persistence representation. It stays inside the adapter:
// no struct tags, no ORM annotations, no domain invariants.
type courseRow struct {
	ID      string
	Name    string
	Version int
}

func toDomain(r courseRow) (*domain.Course, error) {
	id, err := domain.NewCourseID(r.ID)
	if err != nil {
		return nil, fmt.Errorf("map course row: %w", err)
	}
	return domain.NewCourse(id, r.Name, r.Version)
}

func toRow(c *domain.Course) courseRow {
	return courseRow{ID: c.ID().Value(), Name: c.Name(), Version: c.Version()}
}

// Save uses optimistic concurrency: the version column is compared on write.
func (r *PostgresCourseRepository) Save(ctx context.Context, c *domain.Course) error {
	res, err := r.db.ExecContext(ctx, updateCourseSQL,
		toRow(c).Name, toRow(c).Version, toRow(c).ID)
	if err != nil {
		return fmt.Errorf("save course %s: %w", c.ID(), err)
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return fmt.Errorf("save course %s: %w", c.ID(), domain.ErrCourseConflict)
	}
	return nil
}
```

**Checklist (repositories and adapters)**

- [ ] Each port is declared by its consumer and sized to what that consumer needs.
- [ ] Implementations live in the owning context's `infrastructure/persistence/[technology]/`.
- [ ] No persistence technology leaks through domain types or ports.
- [ ] The persistence representation is a separate type inside the adapter, and the mapping functions are explicit.
- [ ] Aggregate consistency, absence, and concurrency semantics are documented.
- [ ] Persistence adapters have real integration/contract tests for the selected engine.
- [ ] No repository is placed in `shared/` just because contexts use the same database.
