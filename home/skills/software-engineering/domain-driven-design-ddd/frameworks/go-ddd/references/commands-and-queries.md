# Commands and Queries

## 2. Commands Implementation

**Location:** `[context-name]/domain/model/commands/`

Commands express an **intention to change state**.

- **Naming:** `[Action][Entity]Command`; file: `[action]_[entity]_command.go`.
- **Use structs** to hold required inputs.
- **Validate input** at construction/application boundaries; the aggregate still protects domain invariants.
- **No HTTP details:** no `gin.Context`, JSON requests, or response codes.

- [ ] Command types end in `Command`.
- [ ] Files end in `_command.go`.
- [ ] Names describe the business action.
- [ ] Required input is validated.
- [ ] Value Objects used for important domain values.
- [ ] No transport/framework dependencies.

**Go note:** This location mirrors the Java guide. For purely application-level input commands, `application/commands/` is also valid; choose **one convention** for the project.

---

## 3. Queries Implementation

**Location:** `[context-name]/domain/model/queries/`

Queries ask for information and **must not modify state**.

- **Naming:** `Get[Entity]By[Field]Query`, `List[Entity]Query`; files end in `_query.go`.
- **Use structs** for filters, paging, and sorting.
- **Validate** page limits, sort keys, and search parameters.
- **Optional parameters:** use pointers when needed; for not-found results, prefer `(value, found bool, error)` or a documented error.

- [ ] Query types end in `Query`.
- [ ] Files end in `_query.go`.
- [ ] Queries have specific, descriptive names.
- [ ] Search criteria validated.
- [ ] Optional data represented explicitly.
- [ ] Pagination/sorting supported where needed.

---
