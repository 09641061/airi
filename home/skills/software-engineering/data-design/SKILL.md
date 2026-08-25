---
name: data-design
description: Design high-performance relational database schemas and persistence architectures — normalization to 3NF/BCNF, explicit foreign keys, check constraints, composite index column ordering (equality before range), deliberate denormalization for read hot-paths, zero-downtime schema migrations (expand/contract), ORM impedance mitigation, and polyglot storage selection. Use when creating or refactoring database schemas, diagnosing slow queries, indexing composite keys, planning zero-downtime migrations, or mapping domain aggregates to SQL.
---

# Relational Data Design & Persistence Architecture

Baseline stack: Relational Databases (PostgreSQL 16+ Standard), SQL DDL, Flyway / Liquibase migrations.

Naming principle is mandatory across the whole physical schema: **`snake_case` plural table names**, immutable `id` surrogate primary keys (`UUIDv7` or `BIGINT`), and explicit foreign keys named `<singular_entity>_id`.

For domain modeling rules determining transactional boundaries and aggregate roots before data modeling begins, see [ddd-core](../domain-driven-design-ddd/ddd-core/SKILL.md).

## Core rules

1. **Normalization (3NF) by default**: Always normalize the logical schema to Third Normal Form (3NF / BCNF) first. Eliminate insertion, update, and deletion anomalies before considering any physical optimizations.
2. **Deliberate denormalization on proven hot-paths only**: Reintroduce redundancy only for measured read bottlenecks with a demonstrated slow query (`EXPLAIN ANALYZE`). Every denormalized field must have an explicit, documented consistency mechanism (transactional triggers, generated columns, or CQRS event projections).
3. **Explicit foreign keys & database constraints**: Enforce referential integrity and business invariants directly in the database engine (`NOT NULL`, `CHECK`, `UNIQUE`, `FOREIGN KEY ... ON DELETE RESTRICT`). Never delegate integrity solely to application code.
4. **Mandatory foreign key indexing**: Explicitly create B-Tree indexes on all foreign key columns. RDBMS engines do not create them automatically; unindexed FKs trigger table-level locks and full sequential scans during parent row deletions and updates.
5. **Composite index column ordering (Equality before Range)**: When creating multi-column indexes, place **exact equality columns first, followed by range/inequality filters, and finally sort columns** (`WHERE tenant_id = ? AND status = ? AND created_at >= ? ORDER BY created_at DESC` → `CREATE INDEX ON table (tenant_id, status, created_at DESC)`).
6. **Immutable surrogate primary keys**: Use immutable surrogate primary keys (`id UUID` or `BIGINT IDENTITY`). Never use mutable business values (email, document number, username) as foreign-referenced physical primary keys.
7. **System audit columns**: Every physical table must include standard UTC audit columns (`created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`, `created_by VARCHAR(100) NOT NULL`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`, `updated_by VARCHAR(100) NOT NULL`).
8. **Zero-downtime schema migrations (Expand / Contract)**: Never execute breaking DDL directly against production. Use the multi-phase Expand/Contract pattern: (1) Expand (add nullable column or view), (2) Migrate (dual-write in application, backfill existing data), (3) Contract (switch read paths to new column, drop legacy column). In PostgreSQL, always build indexes concurrently (`CREATE INDEX CONCURRENTLY`).
9. **No ORM leakage into the domain**: Map persistence entities to domain aggregate roots at repository boundaries. Domain models must never import ORM annotations or expose database-specific data types.
10. **Single source of truth in polyglot architectures**: When using specialized stores (document, key-value, search engine) alongside PostgreSQL, explicitly declare the authoritative source of truth. Synchronize secondary stores asynchronously via transactional outbox events, never dual writes.

## Build order

Follow this order — each step builds on the previous one. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Conceptual & Logical Modeling (Entities, Cardinalities, Boundaries) | [references/conceptual-and-logical-modeling.md](references/conceptual-and-logical-modeling.md) |
| 2 | Relational Normalization (1NF → 2NF → 3NF → BCNF) | [references/normal-forms.md](references/normal-forms.md) |
| 3 | Physical Schema, Constraints & Composite Indexing (Equality First) | [references/schema-conventions.md](references/schema-conventions.md) |
| 4 | Deliberate Denormalization & Consistency Mechanisms | [references/denormalization.md](references/denormalization.md) |
| 5 | Zero-Downtime Schema Migrations (Expand / Contract) | [references/zero-downtime-migrations.md](references/zero-downtime-migrations.md) |
| 6 | Object-Relational Mapping & Impedance Mismatch Mitigation | [references/orm-impedance.md](references/orm-impedance.md) |
| 7 | Polyglot Storage Selection & Architecture Matrix | [references/storage-selection.md](references/storage-selection.md) |
| 8 | Production PostgreSQL DDL, Migrations & Validation Checklist | [references/worked-example.md](references/worked-example.md) |

Before shipping any schema change or migration script, verify compliance with the validation checklist in [references/worked-example.md](references/worked-example.md).
