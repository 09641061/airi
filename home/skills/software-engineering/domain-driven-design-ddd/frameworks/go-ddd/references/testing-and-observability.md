# Testing, Observability, and Reliability

## 13. Testing Requirements

- Unit tests for Value Objects, entities, and aggregate invariants.
- PostgreSQL integration tests for repositories and transaction behavior.
- Gin REST tests with `httptest`, including validation and HTTP codes.
- ACL tests for not-found cases, timeouts, errors, and concurrency.
- Outbox/integration-event tests when events cross contexts.

- [ ] Domain rules and invalid inputs tested.
- [ ] Domain repository contracts tested with fakes; PostgreSQL implementations and database constraints integration-tested.
- [ ] REST request/response contracts tested.
- [ ] ACL failure paths tested.
- [ ] `go test ./...` and `go test -race ./...` included in CI where feasible.

---

## 14. Observability and Reliability

- Structured logs with `slog` and a request/correlation ID.
- Metrics for HTTP latency, failures, DB pool usage, and background jobs.
- OpenTelemetry traces across HTTP, application services, and database calls.
- Idempotency for retryable writes and reliable outbox publishing when needed.

- [ ] Correlation ID passed from Gin to `context.Context` and downstream calls.
- [ ] Operations instrumented without logging credentials.
- [ ] Latency and error alerts configured.
- [ ] HTTP shutdown, timeouts, and health checks implemented.
- [ ] DB pool and background processing monitored.

---
