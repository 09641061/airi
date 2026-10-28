# Architecture and Structure — Placement Decisions

Source: guide introduction, core rules, placement conventions, and §17. Apply to every bounded context. These are project conventions, not folder names mandated by Go or DDD.

## Inspect before restructuring

Identify module/workspace boundaries, declared package names, import cycles, public APIs, generated files, and existing tests. Classify files by their actual responsibilities, not by their current directory labels. Use Go mixed caps with initialisms (`CourseID`, `courseID`, `HTTP`, `URL`) and descriptive `snake_case.go` filenames; avoid package-name stuttering and cosmetic renames of stable APIs.

## Dependency decisions

| Boundary | Put here | Reject here |
|---|---|---|
| `domain/` | Cohesive aggregates, value objects, invariants, policies, optional domain facts | Gin/HTTP, drivers, configuration, logging frameworks, bootstrap, another context's private model |
| `application/` | Use-case inputs/results, orchestration, consumed ports, published application API | Concrete adapters, transport DTOs, engine transactions, aggregate invariants duplicated in handlers |
| `infrastructure/` | Persistence/mapping, outbound clients, publishers, transaction mechanics | Inbound handlers or business policy |
| `interfaces/rest/` | REST resources, binding, handlers, safe HTTP error mapping | Queries to storage, invariants, cross-context orchestration |
| `interfaces/events/` | Message decoding/envelopes, delivery metadata, delegation and ack/nack | A business workflow hidden in a message callback |
| `bootstrap/` | Dependency construction and process lifecycle | A globally accessible service locator or business dependency |

Application consumes domain behavior and narrow ports; adapters depend inward. Constructors normally return concrete implementations. An interface is justified by a real consumer, not the mere existence of a struct.

`interfaces` is not a keyword. Use `interfaces/rest/` here; other projects can legitimately call the HTTP boundary differently. Do not wrap the same endpoints in redundant `interfaces/rest/transport/` layers. Health probes are HTTP mechanics, not necessarily REST resources.

## Illustrative module-root layout

```text
cmd/api/main.go
internal/
  bootstrap/                         # optional; split wiring by context if useful
  enrollments/
    domain/enrollment/
      enrollment.go
      confirmation.go
      confirmation_test.go
    application/
      confirm_enrollment.go          # input/result, consumed port, handler
      confirm_enrollment_test.go
    infrastructure/
      persistence/postgres/
        enrollment_repository.go
        sqlc/                        # optional generated code
      students/                      # outbound integration owned by consumer
    interfaces/
      rest/
        routes.go
        confirm_enrollment.go
        confirm_enrollment_test.go
      events/                        # optional incoming messages
      acl/                           # optional inbound adaptation, not outbound calls
  shared/                            # optional focused capabilities only
    observability/
    httpmiddleware/
test/
  integration/enrollments/persistence/
  integration/enrollments/rest/
  e2e/enrollments/
  e2e/journeys/
```

Create only directories needed by the slice. A small cohesive domain may use one package; larger contexts group related concepts by aggregate/subdomain, not global entities/valueobjects/events buckets. Application can grow into feature packages such as `application/confirmation/` when each has a meaningful API. Do not let a feature import a parent facade that already imports it.

## Split, move, merge, or remove

Review every hand-written Go file exceeding **150 physical lines**, including tests. Decide from responsibilities and reasons to change, not line count alone. Record the proposed action or a short retention rationale in the change/review.

| Action | Apply when |
|---|---|
| Split a file in the same package | Distinct behaviors, adapter query/mapping responsibilities, or test scenario groups can be navigated independently |
| Move a file | Its ownership and dependencies belong to another boundary |
| Extract a package | A cohesive capability needs its own API/encapsulation, not merely fewer lines |
| Merge files | Small declarations are inseparable and change together, such as a use-case input/result |
| Delete | Code is dead, scaffolding empty, an interface unused, or a wrapper/mapper adds no boundary |
| Retain a larger file | Fragmentation would obscure one cohesive responsibility; document why |

Do not use numbered parts, one package per declaration, unrelated loose context-root files, or saturated generic service files. Local `errors.go`, resources, and mapping files are valid when cohesive. `resources/`, `transform/`, commands, and query/service subpackages are optional; preserve useful existing divisions. Never fragment generated/vendor code to meet this threshold: change generator inputs and regenerate.

## Encapsulation and shared code

- Top-level `internal/` restricts outside imports but **not sibling-context imports**. Enforce published-API-only cross-context imports through review and an import allowlist/check. Never access another context's private model, repositories, or tables.
- Nested `internal/` can strengthen boundaries, but root `/test` access must be designed first. A declared package name in another directory does not grant private access. `pkg/` adds no visibility boundary and is neither required nor inherently wrong.
- Keep aggregate internals private; do not export fields to compensate for unnecessary package fragmentation.
- Admit shared code only with actual compatible consumers, an owner, and a stable contract. Prefer focused `shared/observability`, `shared/httpmiddleware`, or client-factory packages, not generic helpers. Focused packages directly under `internal/` are also valid.
- A shared client does not imply shared repositories/data ownership. Process-specific configuration can remain in bootstrap.
- A Shared Kernel is explicitly co-owned domain meaning with governance and compatibility tests; never infer it from similar names. See [context integration](context-integration.md).

Deliver an import map and file-action inventory when auditing. Treat directory changes as justified migrations, not evidence by themselves of architectural improvement.
