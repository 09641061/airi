# Runtime — Composition, Cleanup, and Reliability

Source: guide §§14–15. `cmd/api/main.go` is the process entry. Extract `internal/bootstrap/` when composition benefits from focused files or another process needs the assembly. Neither belongs in domain or as an application dependency.

## Construct only the required process

1. Load/validate runtime settings from the project's selected source and initialize required observability.
2. Initialize necessary clients/resources, registering cleanup as each succeeds.
3. Construct context-owned adapters and inject the narrow ports consumed by application/domain policies.
4. Assemble Gin middleware and `interfaces/rest/` routes, incoming event consumers, and required workers.
5. Configure timeouts/readiness and start accepting work only after required dependencies are ready.
6. On startup failure, unwind initialized resources and return an observable error.
7. On termination, stop accepting work, drain in-flight work with bounded shutdown context, stop workers, and close dependencies in a dependency-safe order.

Keep startup error handling explicit; avoid hidden global registries and business dependencies fetched from bootstrap at runtime. Constructor injection is sufficient. A reflection-based DI framework, dedicated bootstrap package, or generic platform package is not a DDD requirement.

## Configuration and shared capabilities

Keep process settings with composition. Pass each adapter/service only its needed settings or initialized capability, not a global application configuration object. Do not impose YAML, Koanf, a particular engine, a connection pool, ORM, or migration library.

Extract shared loaders/factories only for actual compatible consumers with explicit ownership. A focused `shared/postgres/` factory can be legitimate when PostgreSQL is selected, but repositories and mappings remain context-owned. HTTP middleware belongs to the boundary or genuinely reused `shared/httpmiddleware/`, not a catch-all technical package. See [architecture](architecture-and-structure.md).

Split growing composition by runtime responsibility/context, not arbitrary chunks. Review hand-written files over 150 lines just as in the rest of the project; do not create empty layers to satisfy a tree.

## Observe without contaminating the model

- Use structured logging, normally `log/slog`, at request/application/infrastructure boundaries. Do not inject loggers into domain values for convenience.
- Carry correlation/trace context explicitly through request-scoped I/O, normally first in method signatures. Respect required framework signatures and do not store request context in business structs.
- Measure meaningful service/dependency latency and error signals; adopt OpenTelemetry when operationally justified.
- Record failures without leaking credentials or sensitive payloads to logs or public HTTP responses.
- Define retry bounds, idempotency, concurrency control, and delivery guarantees from actual engine/business requirements; do not assume every storage technology has SQL semantics.
- Do not turn shutdown into a silent loss of acknowledged work; align worker/consumer lifecycle with durability guarantees.

## Verify lifecycle behavior

Check invalid configuration, dependency initialization failure after partial success, cleanup ownership, readiness, request cancellation, server timeouts, worker drain, and bounded shutdown. Verify that closed resources are only those the process initialized and that cleanup order does not invalidate in-flight work prematurely.

Report operational checks actually executed and unresolved infrastructure requirements. Tests and telemetry accompany the feature rather than arriving after every layer is implemented.
