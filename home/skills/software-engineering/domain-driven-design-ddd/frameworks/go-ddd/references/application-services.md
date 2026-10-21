# Application Command and Query Services

## 7. Command Service Implementations

**Location:** `[context-name]/application/commandservices/`

Command Services **coordinate a business use case**: load aggregates, invoke domain behavior, and persist results.

- **Naming:** `[Action][Entity]CommandService` or `[Action][Entity]CommandHandler`.
- **Dependency:** inject the **interface from `domain/repositories/`**, never `Postgres[Entity]Repository` or `*pgxpool.Pool`.
- **Injection:** use constructors; no `@Service`, `@Autowired`, or `Impl` suffix required.
- **Transactions:** the application defines the transaction boundary; infrastructure manages `BeginTx`/`Commit`/`Rollback` behind a small abstraction when multi-step atomic operations require one. Keep `pgx.Tx` out of domain and application.
- **Errors:** return domain-meaningful errors; map them to HTTP in controllers.
- **Context:** receive `context.Context`, not Gin context.

**Constructor dependency pattern:**

```go
package commandservices

import domainrepositories "your.module/internal/[context-name]/domain/repositories"

type EntityCommandService struct {
    repository domainrepositories.EntityRepository
}

func NewEntityCommandService(repository domainrepositories.EntityRepository) *EntityCommandService {
    return &EntityCommandService{repository: repository}
}
```

- [ ] Depends on **`domain/repositories` interfaces**, not infrastructure structs.
- [ ] Dependencies injected through constructor.
- [ ] Domain invariants enforced by aggregates/Value Objects.
- [ ] Transaction boundaries explicit, without database-specific application imports.
- [ ] Errors returned/wrapped meaningfully.
- [ ] Outbox updates share the business transaction when required.

---

## 8. Query Service Implementations

**Location:** `[context-name]/application/queryservices/`

Query Services **fetch data without changing it**.

- **Naming:** `[Action][Entity]QueryService` or `[Action][Entity]QueryHandler`.
- **Dependency:** use domain repository interfaces when querying aggregates; read-model projections can use a separate application query port if appropriate.
- **Read-only:** avoid writes; use read-only transactions only when necessary.
- **Performance:** select required columns, index filters, limit result sizes, and paginate.
- **Context:** propagate `context.Context` for cancellation and timeouts.

- [ ] Implements its query contract when one exists.
- [ ] Constructor injection used.
- [ ] No state mutations.
- [ ] Queries are efficient and bounded.
- [ ] Pagination/sorting handled correctly.
- [ ] Timeouts/cancellation supported.

---
