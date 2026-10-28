# Architecture and Structure

This reference defines the boundaries a Go bounded context must preserve. Example paths are conventions, not a required project tree. Use descriptive business names and keep each module independently understandable.

## Naming

Use descriptive role-based names for contracts and technology-based names for concrete implementations. Exported Go identifiers use `PascalCase`, unexported identifiers use `camelCase`, and filenames use descriptive `snake_case.go`. For example, `CourseRepository` is a business port; `PostgresCourseRepository` identifies an implementation technology when that distinction helps. These are naming examples, not required technologies.

## Dependency and ownership rules

1. **Domain independence:** `domain/` must not import Gin, persistence clients, configuration libraries, HTTP packages, or another bounded context's private domain types.
2. **Ports are consumer-side contracts:** the consumer declares the narrow interface it needs; the adapter satisfies it implicitly. No `implements` keyword, no base interface to inherit.
3. **Application direction:** `application/` depends on domain contracts, never concrete persistence adapters or `*gin.Context`.
4. **Boundary models:** HTTP, ACL, and messaging DTOs stay at their boundaries. Translate explicitly when models cross a boundary; do not create a generic domain mapper framework.
5. **Persistence mapping:** SQL rows, ORM/document models, serialization compromises, and storage-specific tags stay in adapters, not domain types.
6. **No forced abstraction:** do not declare an interface before there is a real usage of it. Accept interfaces, return concrete types. Constructor injection is sufficient; reflection-based DI is optional.
7. **Aggregate consistency:** enforce invariants in domain objects. Coordinate persistence and transactions at application/infrastructure boundaries when required; do not assume storage engines share transaction guarantees.
8. **Transport as the inbound adapter:** HTTP handlers, request/response resources, and HTTP error translation live in `transport/http/` (or `api/http/`). Infrastructure holds persistence, security/framework configuration, messaging, and outbound adapters.
9. **Context boundaries:** integrate through published contracts and an ACL when translation is needed. Do not access another context's private tables, collections, repositories, or domain packages.
10. **Shared Kernel discipline:** a Shared Kernel is a small, intentionally co-owned set of domain concepts and invariants — not a technical-helper package. Create it only by explicit context-mapping agreement.
11. **Technical runtime concerns:** configuration, clients, observability, and process setup are technical concerns. Do not impose a generic `platform/` package or a configuration/database convention.
12. **Public contracts:** document applicable success, validation, authorization, conflict, absence, and server-error responses in OpenAPI.
13. **Understandable modules:** shared code must reduce real duplication without obscuring responsibility or creating hidden context dependencies.
14. **Errors and context:** sentinel or typed errors matched with `errors.Is`/`errors.As`; `context.Context` is the first parameter of any I/O function, never stored in a struct, never `nil`.
15. **Package cohesion:** keep an aggregate with its value objects, states, events, and invariants in one cohesive package.

## Illustrative placement

```text
cmd/api/main.go
internal/bootstrap/                              # optional composition root
internal/shared/infrastructure/config/           # only if configuration reuse is justified
internal/shared/infrastructure/persistence/[technology]/ # optional shared client factory
internal/shared/infrastructure/observability/    # optional shared telemetry setup
internal/[context-name]/domain/                  # cohesive package per aggregate/subdomain
internal/[context-name]/application/             # use-case contracts and orchestration
internal/[context-name]/infrastructure/persistence/[technology]/
internal/[context-name]/transport/http/          # inbound HTTP boundary
```

Do not create all these directories by default. A context may omit layers it does not need. Keep context-owned repositories in the owning context even when a shared technical client factory is used.

## Naming the inbound boundary

Go calls the inbound boundary *transport* (`net/http`). `interface` is both a Go keyword and an overloaded term, and a directory named after a layer type groups code by kind rather than by feature — a cohesion and navigation problem the Go community consistently flags. Use `transport/http/` (or `api/http/`) consistently.

## Package cohesion

A Go package is the unit of cohesion and encapsulation, not a folder that mirrors a file type. Keep an aggregate with its value objects, states, events, and invariants in one cohesive package; split only when a real boundary requires it. Splitting a model into one package per file type creates import cycles, navigation cost, and ceremony without a benefit.

`internal/` is Go's visibility mechanism — packages under it are importable only from the subtree that contains them, which is how a bounded context keeps its internals private. Avoid a top-level `pkg/` directory unless the module publishes a reusable library; it is an outdated convention that adds an import path prefix without adding a boundary.

## Shared infrastructure is not a Shared Kernel

- `internal/shared/infrastructure/` is optional technical reuse: configuration loading, observability initialization, HTTP middleware, or a client factory that multiple contexts genuinely use. It contains no business rules.
- `internal/shared/kernel/` is optional domain code for a narrowly defined set of concepts and invariants that contexts explicitly agree to co-own. It is not the default home for common-looking types.
- Similar names do not guarantee shared meaning. Contexts may model similarly named concepts differently.
- Sharing a client does not share a repository or grant another context access to a context's data.
