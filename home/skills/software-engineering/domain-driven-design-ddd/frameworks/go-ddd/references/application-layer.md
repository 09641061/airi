# Application Layer

The application layer exposes and orchestrates use cases. It depends on domain behavior and contracts; it does not import Gin, concrete persistence adapters, driver/client types, or transport DTOs.

## Commands

Suggested location: `[context-name]/application/commands/` (or an established context command-contract package).

A Command expresses an application intention to change state; it is not a persistence model.

- Use a business-intent name such as `[action]_[entity]_command.go`, exported as `[Action][Entity]Command`.
- Carry only the intent, identifiers, and operation constraints needed by the use case.
- Validate structural input at the entry boundary. Domain behavior must still enforce business rules.
- Do not add Gin, REST DTO, query-client, ORM, or driver-specific fields.
- If a project intentionally places commands under `domain/model/commands/`, preserve that only when they genuinely form part of a domain service API; do not confuse application inputs with domain objects.

## Queries

Suggested location: `[context-name]/application/queries/` (or an established context query-contract package).

A Query requests information without modifying business state.

- Use a name such as `[intent]_query.go`, exported as `[Intent]Query`.
- Keep contracts focused on an information use case.
- Make optional criteria and absence semantics explicit.
- Validate filtering, sorting, pagination, and field constraints; bound page sizes and define deterministic ordering.
- Return a focused application read projection when rebuilding an aggregate is unnecessary. Keep read DTOs/projections out of `domain/`.
- Queries must not mutate aggregates or business state.

## Command Services

Suggested location: `[context-name]/application/commandservices/`.

A Command Service coordinates a state-changing use case: obtain needed aggregate(s), invoke domain behavior, persist the result, and coordinate side effects only when justified.

- Accept `context.Context` and constructor-injected domain ports.
- Invoke domain methods for business rules; do not move invariants into orchestration.
- Preserve business meaning in returned errors.
- Use a transaction/unit-of-work contract only if the operation and selected storage engine require it. Do not assume relational transaction semantics across technologies.
- Make all-or-nothing guarantees, concurrency behavior, and retries explicit when the use-case contract needs them.
- Do not accept `*gin.Context` or concrete storage/client types.
- Wire implementations at the composition root.

## Query Services

Suggested location: `[context-name]/application/queryservices/`.

- Execute read-only use cases with explicit absence and error semantics.
- Use a domain repository if returning aggregates is appropriate; define a separate read port if a projection better serves the query.
- Avoid generic all-purpose data-access services and direct database-implementation dependencies.
- Accept `context.Context`; use bounded pagination and stable sorting.

## Application checklist

- Command and query contracts express use-case intent, not transport or storage representation.
- Application orchestration depends on domain contracts and calls real domain behavior.
- Reads are side-effect-free; writes state their consistency/concurrency guarantees.
- Constructor wiring stays outside domain and application packages.
