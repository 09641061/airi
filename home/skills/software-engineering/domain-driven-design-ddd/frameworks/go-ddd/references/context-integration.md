# Bounded-Context Integration and ACL

A bounded context owns its model and data. Integrate through explicitly published contracts; do not import another context's private domain types or access its tables, collections, or repositories directly.

## Anti-Corruption Layer

An ACL translates a provider's public concepts into the consumer's own language. It is not a global sharing mechanism.

1. Identify the consumer's needed operations and facts.
2. Compare the contexts' meanings, identifiers, states, and error contracts.
3. Define a narrow consumer-facing contract using consumer-owned types; do not expose provider aggregates by default.
4. Publish an intentionally public provider facade in the provider's own application package (`[context-b]/application/`), not inside an HTTP/transport layer — an in-process contract is not an inbound interface. Do not publish repository implementation details.
5. Implement the facade by delegating to provider application services and translating to the published contract.
6. Create consumer-owned value objects for external identifiers/concepts only where needed; enforce consumer invariants.
7. Implement the consumer ACL in the consumer's own boundary — a small `acl` package under `[context-a]/application/` when it only translates in-process results, or under `[context-a]/infrastructure/` when it performs I/O. Translate provider results, errors, and absent values into the consumer's error model. Never use `0` as a not-found sentinel.
8. Inject a consumer-owned port into the consuming use case. Preserve failure semantics and make consistency expectations explicit.

Distinguish missing data, business rejection, timeout/cancellation, and infrastructure failure. Avoid cyclic dependencies. Test provider contract compatibility, translations, missing-data cases, timeouts, and cross-context failure behavior.

**Checklist**

- [ ] No direct imports of another context's internal models or repositories.
- [ ] Provider exposes only an intentionally public contract.
- [ ] Consumer owns the translation into its language.
- [ ] Missing data, business rejection, timeout, and infrastructure error are distinguishable.
- [ ] Cyclic dependencies are avoided; separate shared meaning goes into a Shared Kernel **only by explicit agreement**.
- [ ] Cross-context failure and consistency scenarios are tested.

## Shared Kernel versus shared infrastructure

- A **Shared Kernel** is a small subset of domain meaning/invariants formally and intentionally co-owned by contexts. It is optional, requires an explicit context-mapping decision, and needs joint governance. Prefer `internal/shared/kernel/` if one exists.
- `internal/shared/infrastructure/` is technical reuse only, such as shared configuration loading, telemetry setup, middleware, or a client factory. It contains no business rules and is not a Shared Kernel.
- A shared client does not grant other contexts access to a repository or the owner's data. Keep context-specific adapters under their owning context.
- Do not create `shared/domain/` or a shared package just because types have similar names; models may differ legitimately between contexts.

## Events and delivery

A Domain Event is a fact inside one context; it is not automatically an Integration Event. Cross-context communication happens through explicitly published contracts. When a fact must survive process failure, an outbox record written in the same transaction plus a retrying relay provides at-least-once delivery, and consumers must be idempotent. That mechanism is optional: add it only when durable delivery is a real requirement and the selected storage engine supports its semantics.
