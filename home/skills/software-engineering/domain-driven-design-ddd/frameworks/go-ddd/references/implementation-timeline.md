# Implementation Timeline

## 11. Implementation Timeline

1. **Value Objects** — implement IDs and validated values.
2. **Enums** — define typed constants for statuses and types.
3. **Commands** — define state-changing intentions.
4. **Queries** — define information requests.
5. **Domain Services** — add business capabilities that do not belong to an aggregate.
6. **Entities** — implement identities and domain behavior.
7. **Aggregates** — define consistency boundaries and invariants.
8. **Events** — define meaningful domain facts.
9. **Repositories** — define interfaces in `domain/repositories/`, then implement them in `infrastructure/persistence/postgres/repositories/`.
10. **Command Services** — orchestrate writes and transactions.
11. **Query Services** — implement reads and pagination.
12. **Resources (DTOs)** — create REST request and response types.
13. **Controllers** — expose Gin routes and HTTP responses.
14. **Transformers** — add explicit conversions at boundaries when necessary.
15. **Outbox/Integration** — persist integration events reliably when needed.

---
