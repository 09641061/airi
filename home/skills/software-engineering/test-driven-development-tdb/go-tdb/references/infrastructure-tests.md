# Infrastructure Tests

Location: `internal/<context>/infrastructure/persistence/`

Infrastructure tests verify that the SQL, mappings, and constraints actually work against a real database. They are **integration tests**, not unit tests, and they live behind a build tag.

## The rule

```text
application
   ↓
repository contract

integration test
   ↓
PostgreSQL implementation
   ↓
real PostgreSQL
```

Do not mock PostgreSQL to prove SQL works. The repository adapter is the boundary under test, and the only way to test it is to run the SQL it produces.

## Stack

- `testcontainers-go/modules/postgres` to spin up a real PostgreSQL
- `pgx/v5` (the same driver the production code uses)
- `golang-migrate` / `goose` / `atlas` to apply migrations before each test
- `//go:build integration` so the test doesn't run on every `go test ./...`

```bash
go test -tags=integration ./...
```

## Test file layout

Co-locate with the adapter, but tag the test file:

```
internal/order/infrastructure/persistence/
  order_repository.go
  order_repository_integration_test.go    # //go:build integration
```

## Container setup

```go
// File: internal/order/infrastructure/persistence/order_repository_integration_test.go
//go:build integration

package persistence_test

import (
    "context"
    "os"
    "testing"
    "time"

    "github.com/jackc/pgx/v5/pgxpool"
    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/modules/postgres"
    "github.com/testcontainers/testcontainers-go/wait"
)

func mustPool(t *testing.T) *pgxpool.Pool {
    t.Helper()
    ctx := context.Background()

    pg, err := postgres.RunContainer(ctx,
        testcontainers.WithImage("postgres:16-alpine"),
        postgres.WithDatabase("order_test"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
        testcontainers.WithWaitStrategy(
            wait.ForLog("database system is ready to accept connections").
                WithOccurrence(2).
                WithStartupTimeout(30*time.Second),
        ),
    )
    if err != nil {
        t.Fatalf("start container: %v", err)
    }
    t.Cleanup(func() { _ = pg.Terminate(ctx) })

    conn, err := pg.ConnectionString(ctx)
    if err != nil {
        t.Fatalf("connection string: %v", err)
    }

    // Apply migrations from the migration directory.
    if err := applyMigrations(ctx, conn); err != nil {
        t.Fatalf("migrate: %v", err)
    }

    pool, err := pgxpool.New(ctx, conn)
    if err != nil {
        t.Fatalf("pool: %v", err)
    }
    t.Cleanup(pool.Close)
    return pool
}
```

Use `testcontainers.WithImage("postgres:16-alpine")` to pin the version your production database uses. Don't let the test drift to whatever `:latest` happens to be.

## Adapter test

```go
func TestOrderRepository_SaveAndFind(t *testing.T) {
    t.Parallel()
    pool := mustPool(t)
    repo := persistence.NewOrderRepository(pool)

    ctx := context.Background()
    order, err := newOrderForTest(t, 1, 42)
    if err != nil {
        t.Fatalf("new order: %v", err)
    }

    if err := repo.Save(ctx, order); err != nil {
        t.Fatalf("save: %v", err)
    }

    got, err := repo.FindByID(ctx, order.ID())
    if err != nil {
        t.Fatalf("find: %v", err)
    }
    if got.ID() != order.ID() {
        t.Fatalf("id = %s, want %s", got.ID(), order.ID())
    }
    if got.Status() != order.Status() {
        t.Fatalf("status = %q, want %q", got.Status(), order.Status())
    }
}

func TestOrderRepository_FindByID_NotFound(t *testing.T) {
    t.Parallel()
    pool := mustPool(t)
    repo := persistence.NewOrderRepository(pool)

    missing, _ := valueobjects.NewOrderID(9999)
    _, err := repo.FindByID(context.Background(), missing)
    if !errors.Is(err, domain.ErrOrderNotFound) {
        t.Fatalf("want ErrOrderNotFound, got %v", err)
    }
}

func TestOrderRepository_UniqueEmailConstraint(t *testing.T) {
    t.Parallel()
    pool := mustPool(t)
    repo := persistence.NewOrderRepository(pool)

    first, _ := newOrderForTest(t, 1, 42)
    if err := repo.Save(context.Background(), first); err != nil {
        t.Fatalf("first save: %v", err)
    }

    second, _ := newOrderForTest(t, 2, 42) // same customer
    err := repo.Save(context.Background(), second)
    if err == nil {
        t.Fatal("expected unique violation, got nil")
    }
    // The adapter should translate the violation to a domain error.
    if !errors.Is(err, domain.ErrOrderAlreadyExists) {
        t.Fatalf("want ErrOrderAlreadyExists, got %v", err)
    }
}
```

The third test is the most important: it proves the adapter translates a database-level constraint into a domain-level error. The application and interfaces layers depend on this translation; without the integration test, it would be untested.

## Migrations in the test

Apply migrations programmatically before each test that needs them. Don't run them once and assume the schema is fresh.

```go
func applyMigrations(ctx context.Context, conn string) error {
    m, err := migrate.New("file://migrations", conn)
    if err != nil {
        return err
    }
    if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
        return err
    }
    return nil
}
```

If migrations are heavy, isolate each test in its own schema or use `BEGIN; ... ROLLBACK;` for the rare read-only case. For most adapter tests, just apply the migrations against the test database.

## Transactions in the test

Test the transaction adapter the same way as the application layer — fake the unit of work, then verify the real one wires through to the database.

```go
func TestUnitOfWork_WithinTx_Commits(t *testing.T) {
    t.Parallel()
    pool := mustPool(t)
    uow := persistence.NewUnitOfWork(pool)

    order, _ := newOrderForTest(t, 1, 42)

    err := uow.WithinTx(context.Background(), func(ctx context.Context) error {
        return persistence.NewOrderRepository(pool).Save(ctx, order)
    })
    if err != nil {
        t.Fatalf("within tx: %v", err)
    }
    // Verify the order is actually persisted after the transaction commits.
}
```

## What NOT to test in infrastructure

- Business rules — those live on the aggregate. The adapter just persists state.
- HTTP — that's the interface layer.
- The application service — that uses a fake repository in its own tests.
- The driver. Don't write tests that exercise `pgx` defaults. Test your code.

## Don't use `pgxmock` / `sqlmock`

These tools mock the database driver. They exercise how your code talks to a mock driver, not how it talks to PostgreSQL. They:

- Don't catch SQL syntax errors
- Don't catch schema mismatches
- Don't catch transaction issues
- Don't catch constraint violations
- Add a parallel "SQL grammar" that has to be kept in sync with the real driver

The repository adapter is the boundary under test. The integration test runs against a real database, end of story. The performance cost of testcontainers is a few seconds of startup; the maintenance cost of `pgxmock` is permanent.

## Checklist

- [ ] Test file has `//go:build integration`
- [ ] PostgreSQL is provisioned via testcontainers, not mocked
- [ ] PostgreSQL image version matches production
- [ ] Migrations are applied before the test runs
- [ ] Test covers `Save` + `Find` round-trip
- [ ] Test covers the "not found" sentinel translation
- [ ] Test covers at least one constraint translation
- [ ] Test covers transaction commit/rollback
- [ ] No `pgxmock`, `sqlmock`, or GORM mock mode
