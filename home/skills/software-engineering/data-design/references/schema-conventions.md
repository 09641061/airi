# Step 3 — Physical schema, constraints & composite index column ordering

A standardized physical schema design for relational databases (PostgreSQL 16+), detailing naming conventions, explicit integrity constraints, audit requirements, and composite indexing algorithms.

## Logical vs. Physical Naming Conventions

| Element | Logical Convention | Physical Convention (PostgreSQL) | Example |
| :--- | :--- | :--- | :--- |
| **Table** | `UpperCamelCase`, singular | `snake_case`, plural | `Customer` → `customers` |
| **Primary Key** | `UpperCamelCase` ID | strictly `id` (`UUID` / `BIGINT`) | `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` |
| **Foreign Key** | Entity + `Id` | `<singular_entity>_id` | `customer_id UUID REFERENCES customers(id)` |
| **Attributes** | `UpperCamelCase` | `snake_case` | `firstName` → `first_name` |
| **Join Table (N:M)**| Combined entities | Domain noun (`snake_case` plural) | `StudentCourse` → `enrollments` |
| **Index** | — | `idx_<table>_<columns>` | `idx_orders_customer_id_created_at` |
| **Unique Index** | — | `uk_<table>_<column>` | `uk_users_email` |
| **Check Constraint** | — | `chk_<table>_<rule>` | `chk_products_unit_price_positive` |

---

## Mandatory System Audit Columns

Every transactional or entity table must include the standard 4 UTC audit columns:

```sql
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
created_by VARCHAR(100) NOT NULL,
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_by VARCHAR(100) NOT NULL
```

Use `TIMESTAMPTZ` (UTC with timezone offset) across all timestamps to eliminate daylight-saving shifts and multi-region clock ambiguity.

---

## Composite Index Column Ordering Rules: Equality Before Range

The order of columns in a multi-column B-Tree index dictates whether the database engine can perform efficient index seek operations or is forced into expensive bitmap index scans and table filters.

```mermaid
flowchart LR
    Col1["1. Equality Columns (=, IS NULL)"] --> Col2["2. Range / Inequality Columns (<, >, BETWEEN)"]
    Col2 --> Col3["3. Sort / Order By Columns (ORDER BY)"]
```

### The Rule: Equality Columns First, Then Range, Then Sort

1. **Equality Filters (`=` / `IN`)**: Place all columns tested with exact equality matches at the **beginning** of the index.
2. **Range Filters (`<`, `>`, `<=`, `>=`, `BETWEEN`)**: Place range columns **after** the equality columns. Once a range column is evaluated in a B-Tree walk, subsequent columns in the index cannot be used for direct branch seeking.
3. **Sort Columns (`ORDER BY`)**: If sorting by a column, append it after the range column (or immediately after equality columns if no range filter is used) to satisfy the sort without an in-memory `Sort` node.

### Concrete Example:

**Target Query:**
```sql
SELECT id, total_amount, created_at
FROM orders
WHERE customer_id = 'c123'         -- Exact equality
  AND status = 'COMPLETED'          -- Exact equality
  AND created_at >= '2026-01-01'    -- Range filter
ORDER BY created_at DESC;           -- Sort matching range
```

**Index Definitions:**
* **CORRECT INDEX (Optimal seek + sort satisfaction):**
  ```sql
  CREATE INDEX idx_orders_customer_status_created 
  ON orders (customer_id, status, created_at DESC);
  ```
  *Plan: Index Condition `(customer_id = 'c123' AND status = 'COMPLETED' AND created_at >= '2026-01-01')`, Zero filter re-checks, Zero temporary sort.*

* **INCORRECT INDEX (Range placed before equality):**
  ```sql
  -- BAD: created_at prevents the engine from seeking status
  CREATE INDEX idx_orders_created_customer_status 
  ON orders (created_at DESC, customer_id, status);
  ```
  *Plan: Reads all rows matching created_at range, then scans every entry filtering customer_id and status.*

---

## Mandatory Foreign Key Indexing

PostgreSQL and other standard relational engines **do not** automatically create indexes on foreign key columns.

```sql
-- Always index foreign key columns explicitly:
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
```

**Consequence of Missing FK Indexes:**
When a row in the parent table (`customers`) is deleted or its primary key updated, the database must execute a **full sequential scan** on the child table (`orders`) while acquiring table-level share locks, paralyzing concurrent writes across the system.

---

## Database-Level Constraints & Data Types

* **Monetary Values**: Use exact numeric types `NUMERIC(14, 2)` or integer cents. Never use floating-point types (`REAL`, `FLOAT`, `DOUBLE PRECISION`).
* **Enumerated Domains**: Use `CHECK (column IN ('PENDING', 'PAID', 'SHIPPED'))` or Postgres `ENUM` types.
* **Positive Boundaries**: Add explicit check constraints for business invariants:
  ```sql
  CONSTRAINT chk_order_items_unit_price CHECK (unit_price >= 0.00),
  CONSTRAINT chk_order_items_quantity CHECK (quantity > 0)
  ```
* **Partial Indexes for Soft Deletes**:
  When using soft deletion (`deleted_at TIMESTAMPTZ`), ensure unique constraints are converted to partial indexes:
  ```sql
  CREATE UNIQUE INDEX uk_users_email_active ON users(email) WHERE deleted_at IS NULL;
  ```
