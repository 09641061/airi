# Testing and Observability

## Testing requirements

- **Domain unit tests:** plain JUnit 5 tests for value objects, aggregate invariants, state transitions, and pure domain policies. They must not boot Spring, Hibernate, or a database.
- **Application tests:** use-case orchestration with contract-faithful fakes or mocks for repositories and outbound ports. Start a Spring context only when proxy or configuration behavior is part of the subject under test.
- **Infrastructure integration tests:** a real or test database for JPA mappings, SQL behavior, constraints, transaction boundaries, and outbox delivery when those are critical. A Mockito test of `JpaRepository` does not prove those behaviors.
- **REST/security contract tests:** validation, authorization, serialization, status codes, and the existing HTTP contract with an MVC slice or an appropriate integration test.
- **Cross-context tests:** the published contract, ACL mapping, consistency timing, duplicate delivery, and the error/retry policy selected by the architecture.
- **E2E:** reserve for high-value complete workflows; do not make every unit scenario boot the entire platform.

### Checklist (testing)

- [ ] Aggregate invariants and state transitions have direct domain tests
- [ ] Application failure paths and orchestration are tested at their ports
- [ ] Critical mappings, constraints, and transaction behavior are tested against a database
- [ ] REST validation and authorization are enforced by tests, not only by API documentation
- [ ] Cross-context event/call consistency and failure behavior are tested
- [ ] A test that boots Spring, Hibernate, or a database is an integration test, whatever its filename says

For the Java/Spring testing conventions in depth (fixtures, Testcontainers, mocking style, quality gates), see the dedicated testing skill: [java-tdb](../../../../test-driven-development-tdb/java-tdb/SKILL.md).

## Observability and reliability

- Structured logging with trace/correlation identifiers at external boundaries.
- **Never log passwords, tokens, secrets, or unnecessary personal data.**
- Latency, error-rate, and throughput metrics on critical workflows; tracing when the deployment supports it.
- Idempotency for retry-prone operations.
- Preserve contract compatibility during architecture refactors.

### Checklist (observability)

- [ ] Correlation id propagated through inbound/outbound calls
- [ ] Critical operations instrumented
- [ ] Alerts for latency and failure rate defined
- [ ] No credentials or sensitive data in logs
