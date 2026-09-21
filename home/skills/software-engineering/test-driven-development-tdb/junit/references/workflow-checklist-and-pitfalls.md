# Workflow, Anti-Patterns & Quality Checklist

This reference is the final delivery checklist: chronological workflow, common failure modes, and production-readiness verification.

### 21. Chronological Step-by-Step Testing Workflow. Scope: Development Timeline

Follow this 14-step workflow when developing any feature, domain aggregate, or use case:

1. **Define SUT & Public Contract:** Identify the class or aggregate under development and establish its public API.
2. **Formulate the 4 Cognitive Questions:** Define what is tested, initial preconditions, stimulus, and verifiable outcome.
3. **Create the Test Class:** Place the class in `src/test/java/` mirroring the production package, appending `Test` (unit) or `IT` (integration).
4. **Establish Fixtures:** Prepare clean SUT instances and collaborators using Test Data Builders or Fakes in `@BeforeEach`.
5. **Implement Nominal Happy Path Test:** Write the primary success scenario following Arrange-Act-Assert.
6. **Apply Descriptive Naming:** Name the method using `should[Behavior]When[Condition]` and add a clear `@DisplayName`.
7. **Formulate Assertions:** Prefer AssertJ fluent assertions (`assertThat`) with descriptive failure messages.
8. **Analyze Partitions & Boundaries (EP/BVA):** Map out valid ranges, boundaries, zero values, and empty inputs.
9. **Implement Boundary Tests:** Write dedicated tests for boundary limits (`boundary - 1`, `boundary`, `boundary + 1`).
10. **Test Failure Contracts:** Verify domain exceptions and error codes using `assertThrows` or `assertThrowsExactly`.
11. **Refactor Redundancy via Parameterized Tests:** Consolidate tabular variations using `@ParameterizedTest` with `@CsvSource` or `@MethodSource`.
12. **Structure State Contexts with `@Nested`:** Organize multi-state business scenarios into hierarchical Given-When-Then inner classes.
13. **Validate Determinism & Concurrency:** Ensure tests pass independently in any order, injecting `Clock.fixed()` for temporal logic and protecting shared resources with `@ResourceLock`.
14. **Verify Mutation Score:** Run PIT mutation testing (`mvn pitest:mutationCoverage`) to verify assertion rigor.

- [ ] Workflow progresses systematically from conceptualization to mutation validation
- [ ] Tests follow standard AAA structure and behavioral naming conventions
- [ ] Happy path, boundary, and negative exception paths are covered
- [ ] Parameterized suites eliminate repetitive assertion code
- [ ] Test suite executes deterministically across CLI runners and CI pipelines

------


### 22. Common Pitfalls to Avoid. Scope: Anti-Patterns

Avoid these fourteen testing anti-patterns when authoring test suites:

1. **The "Fake" Integration Test:**
   - *Problem:* Labeling a test as an "integration test" while mocking all infrastructure or testing static in-memory methods (`assertNotNull(OrderId.generate())`).
   - *Remedy:* Integration tests must verify real infrastructure boundaries (e.g., Spring Data JPA repositories against real PostgreSQL Testcontainers).
2. **Cargo Cult `@AfterEach` Null Assignments:**
   - *Problem:* Writing `order = null;` in `@AfterEach` under the default `PER_METHOD` lifecycle.
   - *Remedy:* Understand that JUnit creates a new test instance per method. Discarded instances are automatically garbage collected. Reserve `@AfterEach` for real cleanup (ThreadLocals, security contexts, open streams).
3. **Brittle Mock Verification with `verifyNoMoreInteractions()`:**
   - *Problem:* Calling `verifyNoMoreInteractions()` on every mock, causing tests to break whenever non-functional interactions (logging, metrics, caching) are added.
   - *Remedy:* Use interaction verification only when the external call is the business contract itself (e.g., charging a card, sending an email). Verify SUT state for query collaborators.
4. **Mocking Domain Models (Entities & Value Objects):**
   - *Problem:* Mocking domain entities bypasses domain validation and invariants, allowing invalid domain states in tests.
   - *Remedy:* Always instantiate real domain objects. Use Test Data Builders to simplify complex aggregate creation.
5. **The Liar Test (Tests Without Meaningful Assertions):**
   - *Problem:* Methods that execute code and pass simply because no exception was thrown, or using `assertDoesNotThrow()` on a state-changing method without verifying the resulting state.
   - *Remedy:* Every test must assert an observable return value, state transition, or emitted event.
6. **False Confidence from Blind Line Coverage:**
   - *Problem:* Assuming an 85% JaCoCo line coverage guarantees quality, even though tests may lack meaningful assertions.
   - *Remedy:* Combine line coverage with Mutation Testing (Pitest) to measure mutant kill ratios.
7. **Thread-Hazardous Preemptive Timeouts (`assertTimeoutPreemptively`):**
   - *Problem:* Spawning separate threads for timeout enforcement, breaking `ThreadLocal` storage (Spring Security, `@Transactional` boundaries, Hibernate sessions).
   - *Remedy:* Use standard `assertTimeout` or declarative `@Timeout`, which execute in the test thread.
8. **Overly Tight Timeouts Causing Flakiness:**
   - *Problem:* Imposing arbitrary 50ms timeouts on integration tests, which fail when CI runners experience CPU throttling.
   - *Remedy:* Treat timeouts as safeguards against hangs/deadlocks (e.g., 5 seconds), not as micro-benchmarks.
9. **Testing Implementation Details & Private Methods:**
   - *Problem:* Testing private methods via reflection or package-private leaks, causing tests to break during harmless internal refactorings.
   - *Remedy:* Test exclusively through the public contract. Extract complex private logic into separate collaborator classes if needed.
10. **The Mystery Guest:**
   - *Problem:* Tests that rely on hidden database records, uncommitted files, or external ambient state not visible in the test method.
   - *Remedy:* Keep preconditions and scenario data explicitly visible inside the Arrange block or via clear Test Data Builders.
11. **Concurrency Failures in Order-Independent Tests:**
   - *Problem:* Assuming tests that pass sequentially are thread-safe, leading to intermittent failures when executed in parallel due to port collisions or static state.
   - *Remedy:* Synchronize access to shared resources using JUnit's `@ResourceLock`.
12. **Blind `@Transactional` Rollbacks Hiding Bugs:**
   - *Problem:* Relying exclusively on `@Transactional` in integration tests, which prevents Hibernate from flushing and conceals database constraint violations or lazy initialization exceptions.
   - *Remedy:* Call `entityManager.flush()` and `clear()`, or use table truncation without `@Transactional` to verify true SQL persistence.
13. **Native Java `assert` Bypassed Without `-ea`:**
   - *Problem:* Using Java's `assert x == y;` statement, which is silently ignored when the JVM runs without the `-ea` flag.
   - *Remedy:* Use AssertJ's `assertThat` or JUnit's `assertEquals`, which throw `AssertionError` unconditionally.
14. **Zombie `@Disabled` Tests:**
   - *Problem:* Disabling tests indefinitely without an issue tracker ticket, accumulating dead code.
   - *Remedy:* Enforce a policy requiring every `@Disabled` annotation to cite an active issue ticket, and fail CI builds on undocumented disabled tests.

- [ ] All fourteen testing anti-patterns are recognized and avoided
- [ ] Integration tests exercise real Testcontainers rather than shallow in-memory doubles
- [ ] Cleanups in `@AfterEach` address genuine external/thread state rather than cargo-cult nulling
- [ ] Assertions verify business contracts rather than internal implementation mechanics

------


### 23. Master Quality Verification Checklist. Scope: Production Readiness

```text
ARCHITECTURE & TEST GRANULARITY
[ ] Unit tests run in memory in milliseconds with zero disk, network, or real database I/O
[ ] Integration tests verify real infrastructure boundaries using Testcontainers (PostgreSQL, Kafka)
[ ] Singleton Container Pattern is leveraged to avoid container restart overhead across classes
[ ] Database migrations (Flyway/Liquibase) execute against the test container upon startup
[ ] Repository tests verify persistence mappings, ID generation, and constraint violations
[ ] Build configuration strictly separates unit tests (Surefire / *Test.java) from integration tests (Failsafe / *IT.java)
[ ] Test classes are categorized with @Tag("unit") or @Tag("integration")

TEST ANATOMY & LIVING SPECIFICATIONS
[ ] Tests adhere to Arrange-Act-Assert (AAA) or Given-When-Then structure
[ ] Concise, single-line tests avoid redundant AAA comment boilerplate
[ ] Act stage focuses on a single primary method invocation
[ ] Test method names follow should[Behavior]When[Condition] or [method]_[scenario]_[result]
[ ] @DisplayName articulates business capability rather than technical method signatures
[ ] Each test method validates a cohesive business behavior or invariant

ASSERTIONS & CONTRACT VERIFICATION
[ ] AssertJ fluent assertions (assertThat) are prioritized for readability and diagnostic diffs
[ ] Object graphs are verified using usingRecursiveComparison() with explicit field exclusions
[ ] Grouped assertions (assertAll or assertSoftly) prevent early fail-fast truncation
[ ] assertThrows is used by default for polymorphic exception hierarchies
[ ] assertThrowsExactly is reserved for scenarios where exact concrete exception types are invariants
[ ] assertDoesNotThrow is avoided for state-changing operations and reserved for idempotent void methods
[ ] Native Java assert keyword is avoided in favor of AssertJ or JUnit assertions

LIFECYCLE, DETERMINISM & CONCURRENCY
[ ] Default @TestInstance(Lifecycle.PER_METHOD) is maintained for test isolation
[ ] Cargo-cult field nullification in @AfterEach is eradicated
[ ] @AfterEach is reserved for resetting SecurityContext, System Properties, or open streams
[ ] Tests run deterministically in any order and are free from @TestMethodOrder in unit suites
[ ] Arbitrary Thread.sleep() is avoided in favor of Awaitility polling or deterministic clocks
[ ] Time-dependent domain logic relies on an injected java.time.Clock.fixed()
[ ] Concurrency conflicts on shared resources are protected using @ResourceLock
[ ] Filesystem component testing isolates disk I/O using @TempDir and is segregated from pure unit tests

TEST DOUBLES & FIXTURES
[ ] Test doubles strictly match Meszaros' taxonomy (Dummy, Stub, Fake, Spy, Mock)
[ ] In-memory Fakes or Stubs are preferred over Mockito mocks where appropriate
[ ] Domain models (Value Objects, Entities, Aggregates) are instantiated as real objects
[ ] @Spy is reserved for refactoring legacy code seams, never for newly designed classes
[ ] verifyNoMoreInteractions() is restricted to external side-effect contracts (payments, emails, audits)
[ ] Test fixtures are managed using Test Data Builders or Object Mother factories
[ ] Complex aggregate state contexts are modeled using @Nested BDD hierarchies
[ ] Repetitive test permutations are consolidated using @ParameterizedTest sources

BUILD PIPELINES, CI & MUTATION QUALITY
[ ] All tests execute cleanly via command-line build tools (mvn test, mvn verify, gradlew test)
[ ] Specific classes and individual methods can be targeted from the CLI
[ ] Pull request pipelines execute tests and enforce quality gates
[ ] Fail-fast is used for local pre-commit checks; full suite runs are used in CI for batch diagnostics
[ ] JaCoCo coverage detects untested code; PIT mutation testing serves as a complementary check for assertion effectiveness
[ ] All @Disabled tests include a required issue tracker reference and justification
```
