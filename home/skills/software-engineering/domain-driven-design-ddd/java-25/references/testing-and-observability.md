# Testing & Observability

## Testing Requirements

- Unit tests for value objects, entities, aggregate invariants.
- Integration tests for repositories.
- API contract tests for REST endpoints.
- ACL integration tests with error scenarios.
- Event publishing tests (including outbox behavior if used).

Checklist:
- [ ] Domain tests cover invariants
- [ ] Repository tests cover critical queries
- [ ] Controller tests validate request/response contracts
- [ ] ACL tests cover timeout/error mapping

## Observability and Reliability

- Structured logging with trace/correlation identifiers.
- Metrics for latency, error rate, and throughput.
- Distributed tracing across bounded contexts.
- Idempotency for retry-prone operations.

Checklist:
- [ ] Correlation id propagated through inbound/outbound calls
- [ ] Critical operations instrumented
- [ ] Alerts for latency and failure rate defined
