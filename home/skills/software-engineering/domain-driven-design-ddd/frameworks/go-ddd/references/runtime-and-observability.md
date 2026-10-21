# Runtime, Configuration, and Observability

Configuration source/format and runtime assembly are implementation choices. Keep runtime concerns outside domain code; do not require a configuration library, database convention, `platform/` package, or dedicated bootstrap package.

## Composition and configuration

`cmd/api/main.go` is the process entry point. It loads and validates runtime settings from the source chosen by the application, initializes only required technical dependencies, builds the dependency graph, mounts Gin routes, starts an `http.Server`, and performs graceful shutdown.

Where reuse is justified, `internal/shared/infrastructure/config/` may contain shared typed configuration loading. A shared factory under `internal/shared/infrastructure/persistence/[technology]/` may initialize a technical client. Context-owned persistence adapters still live under each context and receive that client through constructors. Use `internal/bootstrap/` only when extracting wiring materially improves readability.

### Runtime assembly sequence

1. Load and validate runtime settings.
2. Initialize the HTTP server and Gin middleware.
3. Initialize only the data clients, queues, or services the deployment needs.
4. Construct context-owned adapters and inject them through application/domain ports.
5. Register routes and other inbound adapters.
6. Start the server with suitable timeouts and observability.
7. Handle termination and close only resources actually initialized by this process.

Constructor injection is enough; a reflection-based DI framework is optional.

## Reliability and observability

- Use structured logs at request/application/infrastructure boundaries; do not inject loggers into domain values for convenience.
- Propagate request/correlation and trace context through HTTP, application, ACL, and persistence calls.
- Measure meaningful HTTP and dependency latency/error rates; use OpenTelemetry when tracing/metrics are operationally justified.
- Configure timeouts and graceful shutdown at process/server bootstrap. Propagate cancellation/deadlines to I/O adapters.
- Define retries, idempotency, concurrency control, and consistency according to business needs and the actual adapter guarantees.
- Do not impose SQL transactions, connection pools, or outbox algorithms on technologies with different primitives.
- Make infrastructure failures observable without exposing credentials or sensitive domain data.

**Checklist:** settings are validated; only needed dependencies are initialized; cancellation/timeouts propagate; shutdown releases initialized resources; critical retry/concurrency guarantees are explicit; telemetry focuses on useful service-level signals.
