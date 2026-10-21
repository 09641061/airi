# PostgreSQL Persistence Integration — Real Adapter, Real Database

**Repository contract:** `[context-name]/domain/repositories/`.

**Implementation under test:** `[context-name]/infrastructure/persistence/postgres/repositories/`.

**Rule:** never claim to have tested `Postgres[Aggregate]Repository` by mocking pgx, `sqlc`, `pgxpool`, or the SQL result. That proves fake responses, not SQL behavior.

## Recommended stack

- `github.com/testcontainers/testcontainers-go/modules/postgres` for a disposable real PostgreSQL instance.
- `pgx/v5/pgxpool` (or the exact project PostgreSQL driver).
- Actual `goose` migrations or the production migration runner.
- Go `testing` plus `testify/require` (optional).

No SQLite/H2 substitute for PostgreSQL contracts. No shared developer/production DB. Integration tests may require a container engine in CI.

## Required contract scenarios

| Contract | What a meaningful test must prove |
|---|---|
| Save/retrieve | Persist an actual aggregate, reload it in an independent operation, and verify full domain state. |
| Not found | Correct missing-record contract, no generic zero-value success. |
| Duplicate | Real unique index rejects duplicate, and adapter maps database error correctly. |
| Update | Actual modification persists, unrelated fields preserved. |
| Version conflict | Stale version cannot overwrite newer state; correct error. |
| Multiple rows | Root and child rows remain consistent after reload. |
| Rollback | Error after an earlier write leaves zero partial committed changes. |
| Outbox | Aggregate + integration event commit together, or both roll back. |
| Pagination | Stable deterministic sort/cursor handling with ties and page boundaries. |
| Concurrency | Two conflicting operations cannot violate a DB-backed business invariant. |
| Cancellation | Cancelled context exits without silently reporting success. |
| Schema | Production migrations run cleanly against a fresh DB. |

Do not necessarily implement every row for every repository; select cases mandated by its public contract and schema.

## Integration example: running PostgreSQL

The following is a **real Testcontainers API pattern**. Adapt database name, image, and actual migrations; the repository-specific test remains intentionally generic.

```go
//go:build integration

package repositories_test

import (
    "context"
    "testing"

    "github.com/jackc/pgx/v5/pgxpool"
    "github.com/stretchr/testify/require"
    "github.com/testcontainers/testcontainers-go/modules/postgres"
)

func TestPostgresRepository_Contract(t *testing.T) {
    ctx := context.Background()
    db, err := postgres.Run(
        ctx,
        "postgres:17-alpine", // Pin an org-approved version/digest in CI.
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("testuser"),
        postgres.WithPassword("testpass"),
        postgres.BasicWaitStrategies(),
    )
    require.NoError(t, err)
    t.Cleanup(func() { require.NoError(t, db.Terminate(context.Background())) })

    dsn, err := db.ConnectionString(ctx, "sslmode=disable")
    require.NoError(t, err)
    pool, err := pgxpool.New(ctx, dsn)
    require.NoError(t, err)
    t.Cleanup(pool.Close)
    require.NoError(t, pool.Ping(ctx))

    // Run the SAME migrations as production before constructing the adapter.
    // Then call real Save + FindByID and assert reconstructed domain invariants.
    // This test is deliberately not presented as complete without migrations
    // and a domain-specific repository contract.
}
```

**Portability note:** keep library versions pinned by `go.mod`; check the Testcontainers release API used by the project. Code shown is a harness, not a fake passing assertion.

## Isolation, deterministic setup, and teardown

- Apply migrations against each fresh test database; fail if migrations fail.
- Prefer independent DB/schema for concurrent tests or serialize destructive setup; use `TRUNCATE ... RESTART IDENTITY CASCADE` only in a dedicated test database.
- A rollback-based fixture is safe only if the repository uses the **same transaction/connection**; a separate pool operation will not see the uncommitted data.
- Do not use `t.Parallel()` for suites sharing mutable tables unless state is partitioned and concurrency itself is being tested.
- Use fixed test timestamps and predictable IDs; avoid `time.Sleep` to wait for eventual persistence.
- Pin image/version and ensure the container runtime is present in CI.

## Transaction correctness (essential)

Design tests for a failure injected **after the first successful SQL write but before the next commit**. Assert via a fresh connection that neither aggregate nor outbox record committed. A unit test with `Begin()`/`Rollback()` calls alone cannot prove this.

For concurrent uniqueness or optimistic-version constraints, start two independent operations with deliberate coordination; assert the database state and that at most the permitted operations succeeded. `-race` does not replace SQL isolation testing.

## Checklist

- [ ] Real PostgreSQL with production migrations.
- [ ] Real infrastructure adapter satisfies `domain/repositories` contract.
- [ ] Save–reload reconstructs business state, including child invariants.
- [ ] Missing/duplicate/conflict errors are translated correctly.
- [ ] Transaction rollback and outbox atomicity tested when relevant.
- [ ] Concurrency and paging semantics tested where contract requires.
- [ ] Test DB is isolated; cleanup is reliable; CI can reproduce it.
