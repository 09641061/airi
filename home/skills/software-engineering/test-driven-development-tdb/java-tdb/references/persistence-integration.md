# Persistence Adapter Tests (JPA / Spring Data)

Location: `src/test/java/[base-package]/[context-name]/infrastructure/persistence/`

These are **integration tests**, not unit tests. They live next to the production code they exercise, and they require a real database (Testcontainers PostgreSQL, embedded H2/Postgres for fast local runs, or an in-memory Testcontainers-managed instance).

## What to cover

- Custom `@Query` methods declared in the JPA repository adapter.
- Mappings between the domain aggregate and the JPA entity (including embeddables, value-object converters, lazy/eager fetch strategy).
- Database-level constraints (`UNIQUE`, `CHECK`, `NOT NULL`, foreign keys) when they encode business invariants.
- Optimistic-locking columns and their handling of stale updates.
- Transaction boundaries on multi-write operations.

## What NOT to do

- Do not unit-test `JpaRepository` defaults (`save`, `findById`, `delete`, derived queries) — Spring Data provides them.
- Do not mock the JPA entity manager or the repository in these tests; use a real database.
- Do not run these tests against a production database or a shared dev database.

## Tagging and CI

- Tag integration tests with JUnit 5 `@Tag("integration")`.
- Run them in CI against disposable infrastructure (Testcontainers).
- Keep them fast: a single context's persistence tests should finish in seconds, not minutes.

## Checklist

- [ ] Real database used; Spring context loaded with the JPA configuration
- [ ] Custom `@Query` methods covered
- [ ] Embeddable / value-object mappings covered
- [ ] Database constraints verified
- [ ] Tests tagged `@Tag("integration")`
- [ ] No Spring Data defaults retested
