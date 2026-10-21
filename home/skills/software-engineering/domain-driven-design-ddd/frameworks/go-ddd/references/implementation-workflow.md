# Implementation Workflow

Use this as a suggested progression, not as a requirement to create every layer or artifact. Discover actual context ownership and requirements first; preserve established conventions when they respect the same boundaries.

1. Define and test Value Objects with meaningful invariants.
2. Model valid states and transitions.
3. Define Commands as state-changing application intentions.
4. Define Queries as read-use-case contracts.
5. Introduce Domain Services only for justified policies/calculations.
6. Model Entities and their identity/lifecycle behavior.
7. Define Aggregates and enforce their consistency invariants.
8. Add Domain Events for meaningful completed facts when needed.
9. Define aggregate repository ports under `domain/repositories/`.
10. Implement required adapters in the owning context's `infrastructure/persistence/[technology]/`.
11. Add Command Services for justified mutations and consistency coordination.
12. Add Query Services/projections for justified read use cases.
13. Define REST resources and OpenAPI contracts if the context exposes HTTP.
14. Add Gin controllers as HTTP adapters.
15. Wire the process in `cmd/api/main.go` or optional `internal/bootstrap/`.
16. Integrate contexts through explicit contracts and ACL translation.
17. Add an outbox or coordination mechanism only for a demonstrated reliability need and supported adapter semantics.
18. Verify domain, persistence, API, cross-context, and operational behavior with appropriate tests and observability.

## Final review

- [ ] Domain is pure business code, independent of Gin, persistence, configuration, and private types from other contexts.
- [ ] Repository ports are owned by the domain; implementations are owned by the context's infrastructure.
- [ ] Application services depend on contracts, not Gin or concrete database clients.
- [ ] DTOs, serialization tags, and storage mapping stay at boundaries/adapters.
- [ ] Persistence and configuration choices remain optional and technology-neutral.
- [ ] Shared technical infrastructure and an explicitly co-owned Shared Kernel are not conflated.
- [ ] ACL preserves the consumer's own model and failure semantics.
- [ ] Transactions, consistency, concurrency, retries, and delivery match actual technology guarantees and use-case requirements.
- [ ] Business behavior and selected adapter/API contracts have meaningful tests.
- [ ] Runtime setup initializes only needed resources and shuts them down cleanly.
