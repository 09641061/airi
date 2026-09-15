# Testing & Observability

## Testing Requirements

Tests are split by layer. Mixing them defeats their purpose.

- **Domain unit tests** — value objects, entities, aggregate invariants, domain services, domain events. **Pure JUnit 5 + AssertJ/Mockito. No `@SpringBootTest`, no `@DataJpaTest`, no Hibernate, no JPA, no database.** Domain tests do not even have Spring or Hibernate on the test classpath unless an integration test for the same module needs it. Domain aggregates and value objects are constructed and exercised through their public methods only.
- **Application unit tests** — command/query services. Plain JUnit + Mockito; the domain repository ports and outbound ACL facades are mocked. **No Spring context, no database.** A `@SpringBootTest` slice for an application service is acceptable only if the orchestration under test genuinely requires Spring's proxy machinery; document it in the test header.
- **Infrastructure integration tests** — JPA mappings, repository adapters, outbox, ACL adapters. These use a real database (Testcontainers, embedded H2/Postgres) and exercise the JPA layer end-to-end. They are tagged separately (`@Tag("integration")`) and live in `src/test/java/.../infrastructure/` alongside the production code they cover.
- **REST contract tests** — controllers, resources, transformers, error handlers. `@WebMvcTest` slice, mocked services, no DB.
- **End-to-end tests** — happy paths across bounded contexts; exercise only what's worth a full deploy.

A test is a "unit" only if it runs in milliseconds without external processes. Anything that boots Spring, Hibernate, a database, or a message broker is an integration test, even if the file is named `*Test`.

Checklist:
- [ ] Domain unit tests use plain JUnit + AssertJ/Mockito; no Spring/Hibernate/JPA/DB on the classpath
- [ ] Application unit tests mock the domain ports (repositories, outbound services)
- [ ] JPA mappings, queries, and constraints are exercised only in infrastructure integration tests with a real database
- [ ] ACL tests verify timeout, error translation, and unmapped-error handling
- [ ] Coverage is generated and a quality gate is enforced

## Observability and Reliability

- Structured logging with trace/correlation identifiers.
- Metrics for latency, error rate, and throughput.
- Distributed tracing across bounded contexts.
- Idempotency for retry-prone operations.

Checklist:
- [ ] Correlation id propagated through inbound/outbound calls
- [ ] Critical operations instrumented
- [ ] Alerts for latency and failure rate defined
