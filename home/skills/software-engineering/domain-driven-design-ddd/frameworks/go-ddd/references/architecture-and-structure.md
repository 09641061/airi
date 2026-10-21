# Architecture and Structure

This reference defines the boundaries a Go bounded context must preserve. Example paths are conventions, not a required full project tree. Use descriptive business names and keep each module independently understandable.

## Naming

Use descriptive role-based names for contracts and technology-based names for concrete implementations. Exported Go identifiers use `PascalCase`, unexported identifiers use `camelCase`, and filenames use descriptive `snake_case.go`. For example, `EntityRepository` is a business port; `PostgresEntityRepository` or `MongoEntityRepository` identifies an implementation technology when that distinction helps. These are naming examples, not required technologies.

## Mandatory dependency and ownership rules

1. **Domain independence:** `domain/` must not import Gin, persistence clients, configuration libraries, HTTP packages, or another bounded context's private domain types.
2. **Repository ownership:** repository interfaces belong to `[context-name]/domain/repositories/`; concrete adapters belong to that context's `infrastructure/persistence/[technology]/`.
3. **Application direction:** `application/` depends on domain contracts, never concrete persistence adapters or `*gin.Context`.
4. **Boundary models:** HTTP, ACL, and messaging DTOs stay at their boundaries. Translate explicitly when models cross a boundary; do not create a generic domain mapper framework.
5. **Persistence mapping:** SQL rows, ORM/document models, serialization compromises, and storage-specific tags stay in adapters, not domain types.
6. **No forced abstraction:** create interfaces for actual consumer contracts and replaceable boundaries. Constructor injection is sufficient; reflection-based DI is optional.
7. **Aggregate consistency:** enforce invariants in domain objects. Coordinate persistence and transactions at application/infrastructure boundaries when required; do not assume storage engines share transaction guarantees.
8. **Context boundaries:** integrate through published contracts and an ACL when translation is needed. Do not access another context's private tables, collections, repositories, or domain packages.
9. **Shared Kernel discipline:** a Shared Kernel is a small, intentionally co-owned set of domain concepts and invariants—not a technical-helper package. Create it only by explicit context-mapping agreement.
10. **Technical runtime concerns:** configuration, clients, observability, and process setup are technical concerns. Do not impose a generic `platform/` package or configuration/database convention.
11. **Public contracts:** document applicable success, validation, authorization, conflict, absence, and server-error responses in OpenAPI.
12. **Understandable modules:** shared code must reduce real duplication without obscuring responsibility or creating hidden context dependencies.

## Illustrative placement

```text
cmd/api/main.go
internal/bootstrap/                              # optional composition root
internal/shared/infrastructure/config/           # only if configuration reuse is justified
internal/shared/infrastructure/persistence/[technology]/ # optional shared client factory
internal/shared/infrastructure/observability/    # optional shared telemetry setup
internal/shared/kernel/                           # optional, deliberately co-owned domain code
internal/[context-name]/domain/model/valueobjects/
internal/[context-name]/domain/model/entities/
internal/[context-name]/domain/model/events/
internal/[context-name]/domain/services/
internal/[context-name]/domain/repositories/
internal/[context-name]/application/
internal/[context-name]/infrastructure/persistence/[technology]/
internal/[context-name]/interfaces/rest/
```

Do not create all these directories by default. A context may omit layers it does not need. Keep context-owned repositories in the owning context even when a shared technical client factory is used.

## Shared infrastructure is not a Shared Kernel

- `internal/shared/infrastructure/` is optional technical reuse: for example, configuration loading, observability initialization, HTTP middleware, or a client factory that multiple contexts genuinely use. It contains no business rules.
- `internal/shared/kernel/` is optional domain code for a narrowly defined set of concepts and invariants that contexts explicitly agree to co-own. It is not the default home for common-looking types.
- Similar names do not guarantee shared meaning. Contexts may model similarly named concepts differently.
- Sharing a client does not share a repository or grant another context access to a context's data.
