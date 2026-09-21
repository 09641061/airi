---
name: junit
description: Apply production-grade JUnit Jupiter testing principles for Java unit and integration tests, including behavioral naming, test boundaries, assertions, lifecycle management, Testcontainers, Mockito, Awaitility, CI quality gates, and mutation testing. Use whenever asked to write, review, structure, or improve JUnit tests in Java or Spring projects.
---

# JUnit Jupiter Test Engineering

Use this skill to design, write, review, or refactor high-quality Java tests. Tests are **executable specifications**: their names and assertions must document business rules, invariants, failure contracts, and required infrastructure collaboration.

This skill separates framework facts from engineering recommendations and team policy:

- **JUnit fact:** behavior guaranteed by JUnit Platform/Jupiter APIs and lifecycle rules.
- **Engineering recommendation:** a maintainability, diagnostic, or architectural default.
- **Team policy:** a repository or CI rule that must be confirmed from the target project.

## Recommended stack

```text
JUnit Jupiter 5.11+ / JUnit 6.1.3+
AssertJ 3.26+
Mockito 5+
Testcontainers 1.20+
Awaitility 4.2+
PIT/Pitest 1.16+
JaCoCo 0.8.12+
Maven Surefire/Failsafe or Gradle Test/integrationTest
Java 17+ / Java 21 LTS
```

Use the versions already declared by the project when they differ from this baseline.

## Non-negotiable boundaries

### Unit tests

Unit tests must be:

- fast and isolated in memory;
- deterministic and order-independent;
- free of real database, network, socket, process, and filesystem I/O;
- focused on one SUT behavior;
- self-validating with meaningful assertions.

Use real domain objects and substitute external collaborators with an appropriate Dummy, Stub, Fake, Spy, or Mock.

### Integration and component tests

Integration/component tests verify real boundaries: JPA mappings, SQL dialect behavior, migrations, transactions, filesystem behavior, message brokers, or external wire contracts. Use controlled, ephemeral infrastructure such as Testcontainers rather than pretending that H2 or an in-memory mock is PostgreSQL.

Keep slow tests separate from unit tests:

- unit classes: `*Test.java`, normally tagged `unit`, run by Surefire/Gradle `test`;
- integration classes: `*IT.java`, normally tagged `integration`, run by Failsafe/Gradle `integrationTest`.

Explicitly clean persistent state and flush/clear persistence contexts where the behavior under test depends on real SQL semantics.

## Test contract

Before writing a test, identify the SUT and answer:

1. **What is being tested?** The class, operation, invariant, or public contract.
2. **What are the initial conditions?** Only the relevant inputs, state, and collaborator responses.
3. **What is the stimulus?** One primary command, query, or method call.
4. **What is observable afterward?** A return value, state transition, exception contract, emitted event, or required outbound message.

Test public behavior, not private implementation details. Do not use reflection to test private methods. Extract complex private behavior into a collaborator with its own public contract.

## Default test shape

Use Arrange–Act–Assert or Given–When–Then:

```java
@Test
void shouldApplyDiscountWhenCustomerIsVip() {
    // Arrange: relevant preconditions and real domain fixtures
    Order order = anOrderWithSubtotal("200.00");
    OrderPricingPolicy policy = new OrderPricingPolicy();

    // Act: one primary stimulus
    Money total = policy.calculateEffectiveTotal(order, CustomerType.VIP);

    // Assert: observable business outcome
    assertThat(total.amount()).isEqualByComparingTo("180.00");
}
```

Use explicit AAA comments only when setup is non-trivial. Multiple assertions are acceptable when they describe one cohesive outcome; avoid multiple sequential Act–Assert cycles in one test.

## Naming, assertions, and failure contracts

- Prefer `should[Behavior]When[Condition]` or `[method]_[scenario]_[result]`.
- Use `@DisplayName` when it improves domain readability; use `@DisplayNameGeneration` for consistent suites.
- Do not use generic names such as `testOrder`, `check`, or `runScenario`.
- Prefer AssertJ for collections, object graphs, recursive comparisons, and diagnostic failure messages.
- Use JUnit assertions for simple scalar checks when they are clearer.
- Use `assertThrows` for polymorphic exception contracts.
- Use `assertThrowsExactly` only when the concrete exception type is itself part of the contract.
- Inspect exception messages, error codes, causes, or structured details when those are observable requirements.
- Do not use `assertDoesNotThrow` as a substitute for verifying a state change.
- Never use Java's native `assert` for test verification.

See [assertions-and-failure-contracts.md](references/assertions-and-failure-contracts.md).

## Lifecycle, determinism, and asynchronous behavior

- Keep JUnit's default `PER_METHOD` lifecycle unless a shared read-only fixture genuinely requires `PER_CLASS`.
- Do not set fields to `null` in `@AfterEach`; clean only external state such as security contexts, system properties, thread-locals, streams, sockets, or shared caches.
- Inject `Clock` and use `Clock.fixed(...)` for time-dependent domain logic.
- Avoid `Thread.sleep()`; use Awaitility with a tolerant deadline and polling interval.
- Prefer `@Timeout` or non-preemptive `assertTimeout` for hang protection.
- Avoid `assertTimeoutPreemptively` around Spring transactions, security contexts, JPA sessions, or other `ThreadLocal`-bound infrastructure.
- When parallel execution is enabled, protect shared global resources with `@ResourceLock` or eliminate the shared state.
- Use assumptions only for environmental prerequisites, never for business rules.
- Use `@TempDir` for filesystem component tests; keep serialization/formatting unit tests in memory.

See [lifecycle-determinism-and-async.md](references/lifecycle-determinism-and-async.md).

## Test doubles and fixtures

Choose the least coupled double that proves the contract:

- **Dummy:** satisfies a parameter but is not used;
- **Stub:** returns controlled values;
- **Fake:** functional in-memory implementation;
- **Spy:** records calls while delegating to a real object;
- **Mock:** verifies an interaction contract.

Prefer state and outcome verification over interaction verification. Verify outbound interactions only when the interaction is the business contract, such as charging a card, sending an email, dispatching a transfer, or recording an immutable audit event. Reserve `verifyNoMoreInteractions` for those strict contracts.

Never mock the SUT, value objects, entities, or aggregates. Prefer deterministic Test Data Builders or Object Mothers over random data and oversized fixture setup.

See [doubles-and-fixtures.md](references/doubles-and-fixtures.md).

## Design techniques

Apply the technique that matches the behavior:

- **Equivalence Partitioning and Boundary Value Analysis:** cover representative valid/invalid partitions and `min - 1`, `min`, `min + 1`, `max - 1`, `max`, `max + 1` where applicable.
- **Parameterized tests:** use `@ValueSource`, `@NullAndEmptySource`, `@EnumSource`, `@CsvSource`, `@CsvFileSource`, or typed `@MethodSource` when the algorithm is the same and only data varies.
- **`@Nested`:** model meaningful Given/When state contexts for aggregates; do not use it to hide unrelated tests.
- **Contract assertions:** verify public outcomes so internal refactors remain safe.
- **Grouped assertions:** use `assertAll` or AssertJ soft assertions only for one cohesive result.

See [test-design-and-organization.md](references/test-design-and-organization.md).

## Build, integration, and CI rules

- Configure Maven with Surefire for unit tests and Failsafe for integration tests, or configure equivalent Gradle tasks.
- Enable the JUnit Platform (`useJUnitPlatform()` in Gradle; compatible Surefire/Failsafe in Maven).
- Run Flyway/Liquibase migrations against the real Testcontainer when persistence compatibility is under test.
- Prefer a JVM-scoped singleton container when it reduces startup cost and database cleanup remains reliable.
- Treat JaCoCo as execution coverage, not proof of assertion quality.
- Scope PIT mutation testing to business-critical domain/application packages; calibrate thresholds as team policy.
- Use fail-fast locally for rapid feedback; run the full suite in centralized CI for complete diagnostics.
- Every `@Disabled` test must include an actionable issue reference and reason, according to project policy.

See [fundamentals-and-scope.md](references/fundamentals-and-scope.md) and [build-integration-and-ci.md](references/build-integration-and-ci.md).

## Execution workflow

Follow this order when adding or reviewing tests:

1. Define the SUT and public contract.
2. Answer the four test-contract questions.
3. Classify the test as unit, component, integration, or end-to-end.
4. Create the test in the matching package and use `Test`/`IT` naming.
5. Establish deterministic fixtures with builders, fakes, or targeted stubs.
6. Write the nominal behavior using AAA/Given–When–Then.
7. Add behavioral naming and readable display names.
8. Add partitions, boundaries, malformed inputs, and failure contracts.
9. Consolidate genuinely repetitive data with parameterized tests.
10. Organize stateful aggregate contexts with `@Nested` when it improves discovery.
11. Check order independence, time control, parallel-resource safety, and async polling.
12. Run targeted tests, the relevant suite, integration tests, coverage, and mutation testing according to project policy.

The complete workflow, anti-pattern catalog, CLI commands, and production checklist are in [workflow-checklist-and-pitfalls.md](references/workflow-checklist-and-pitfalls.md).

## Reference map

Load only the reference needed for the current task:

| Need | Reference |
|---|---|
| JUnit Platform/Jupiter/Vintage, SUT boundaries, unit vs integration, Testcontainers | [fundamentals-and-scope.md](references/fundamentals-and-scope.md) |
| AAA, naming, boundaries, parameterized tests, `@Nested`, contract testing | [test-design-and-organization.md](references/test-design-and-organization.md) |
| AssertJ/JUnit assertions and exception contracts | [assertions-and-failure-contracts.md](references/assertions-and-failure-contracts.md) |
| Lifecycle, assumptions, timeouts, async, concurrency, `@TempDir` | [lifecycle-determinism-and-async.md](references/lifecycle-determinism-and-async.md) |
| Mockito, fakes, spies, builders, object mothers | [doubles-and-fixtures.md](references/doubles-and-fixtures.md) |
| Maven/Gradle, Surefire/Failsafe, CI, JaCoCo, PIT | [build-integration-and-ci.md](references/build-integration-and-ci.md) |
| End-to-end workflow, anti-patterns, final checklist | [workflow-checklist-and-pitfalls.md](references/workflow-checklist-and-pitfalls.md) |

## Minimum quality gate

Before considering a test suite complete, confirm:

- tests describe behavior and use deterministic data;
- each test has a meaningful observable assertion;
- unit tests do not perform infrastructure I/O;
- integration tests use real, controlled infrastructure when the boundary matters;
- exception, boundary, and failure paths are covered;
- tests are independent, runnable from the CLI, and separated by cadence;
- no private implementation details, random timing, arbitrary sleeps, or undocumented disabled tests weaken the suite;
- coverage and mutation results are interpreted as complementary evidence, not as a single quality score.
