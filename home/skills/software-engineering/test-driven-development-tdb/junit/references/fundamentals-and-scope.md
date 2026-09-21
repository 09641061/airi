# Fundamentals, Scope & Test Architecture

This reference covers the testing model, JUnit engines, SUT boundaries, and the distinction between unit and integration tests.

# JUnit Testing Guide: Pragmatic Engineering Principles for High-Quality Tests

This guide provides a comprehensive, production-grade approach for designing, structuring, and maintaining **unit and integration tests** in Java using JUnit Jupiter (JUnit 5.11+ and JUnit 6.1.3+). Each section establishes explicit testing responsibilities, behavioral naming conventions, architectural boundaries, assertion contracts, lifecycle management, and CI quality gates.

**“Descriptive/Behavior-based Naming”** or **“Executable Specifications”** is the guiding principle: test suites must serve as living, unambiguous documentation of business rules, system invariants, and infrastructure collaboration contracts.

Recommended stack:

```text
JUnit Jupiter (JUnit 5.11+ / JUnit 6.1.3+)
AssertJ 3.26+
Mockito 5+
Testcontainers 1.20+ (PostgreSQL, Kafka, LocalStack)
Awaitility 4.2+
PIT Mutation Testing (Pitest 1.16+)
JaCoCo 0.8.12+
Maven Surefire & Failsafe / Gradle Test & IntegrationTest Runner
Java 17+ / Java 21 LTS
```

### Fundamental Testing Axioms & Properties: Unit vs. Integration

A common architectural error is applying identical rules to all automated tests. Automated testing exists along a spectrum where unit tests and integration tests satisfy fundamentally distinct engineering trade-offs:

#### Unit Test Properties (FIRST Principles)
1. **Fast (Milliseconds):** Pure unit tests execute in single-digit milliseconds to sustain uninterrupted TDD flow and instant local feedback loops.
2. **Isolated in Memory:** Collaborator boundaries are substituted with in-memory doubles (Fakes, Stubs, Mocks) or deterministic fixtures. Zero disk, socket, network, or process I/O.
3. **Deterministic:** Given identical inputs, a test produces identical outcomes regardless of execution order, time of day, operating system, or concurrency.
4. **Automated & Self-Validating:** No manual intervention or human interpretation of logs is required to determine pass/fail status.
5. **Focused Scope:** Exercises an isolated unit of logic (Domain Entity, Value Object, Domain Service, or Use Case orchestrator) to pinpoint failures immediately.

#### Integration Test Properties
1. **Collaboration Verification:** Exercises real interactions across architectural boundaries—such as Object-Relational Mapping (ORM/JPA), SQL dialect compatibility, transactional boundaries, schema migrations, and external wire protocols.
2. **Controlled & Ephemeral Infrastructure:** Relies on production-like, ephemeral infrastructure orchestrated via **Testcontainers** (e.g., real PostgreSQL, Redis, or Kafka instances) rather than brittle, shared external servers or simplistic in-memory mocks (e.g., H2).
3. **Repeatable Data Fixtures:** Manages explicit database state, controlled transaction rollbacks, or targeted table truncations to guarantee that test executions remain repeatable.
4. **Explicit State Boundaries:** Acknowledges that persistence contexts, cache layers, and schema validations introduce real latency and side effects that must be explicitly verified and reset.
5. **Deliberate Execution Cadence:** Slower by nature due to container startup and disk/socket I/O; separated from unit tests in the build lifecycle to maintain high developer velocity.

### Epistemological Clarity: Three Knowledge Tiers

To eliminate dogmatism and distinguish framework realities from organizational choices, this guide explicitly classifies principles into three tiers:

- **`[JUnit Fact]`:** Inherent specifications and execution mechanics implemented by the JUnit Platform and Jupiter engine.
- **`[Engineering Recommendation]`:** Battle-tested architectural patterns, design heuristics, and industry best practices that maximize test maintainability and diagnostic clarity.
- **`[Project / Team Policy]`:** Explicit governance rules, CI quality gates, and workflow conventions chosen by an engineering organization to enforce consistency across a shared codebase.

------


### 1. Test Architecture & Engine. Scope: JUnit Platform, Jupiter & Vintage (Java 17+)

Automated software testing is the programmatic verification of whether the actual behavior of a System Under Test (SUT) matches its specified expected behavior under declared preconditions. In modern Java ecosystems, JUnit provides the foundational test execution architecture through a modular three-part platform.

- **Test Containers vs Tests:** A test container is a structural grouping node in the test discovery tree (such as a test class, a nested class context, or a parameterized test invocation container) that orchestrates discovery and lifecycle. A test is an individual executable leaf node that exercises a scenario and asserts postconditions.
- **The JUnit Modular Triad:**
  - **JUnit Platform:** The foundational execution framework, test discovery engine, launcher API, and command-line entry point that IDEs (IntelliJ IDEA, Eclipse, VS Code) and build tools (Maven, Gradle) interface with.
  - **JUnit Jupiter:** The modern programming model, extension architecture, and annotation set (`@Test`, `@BeforeEach`, `@Nested`, `@ParameterizedTest`) native to modern Java (Java 17 through 21+).
  - **JUnit Vintage:** A legacy execution engine providing an implementation of the `TestEngine` interface to run JUnit 3 and JUnit 4 test suites on the modern JUnit Platform. In modern Java projects, Vintage should generally be excluded from dependencies unless maintaining legacy test suites.
- **JUnit 5 vs JUnit 6:** JUnit 6 (with stable baseline 6.1.3+ in 2026) raises the minimum runtime requirement to Java 17+, delivering native compatibility with Java 21 virtual threads (Project Loom), deep integration with Java Module System (JPMS), streamlined engine SPIs, and backward compatibility with the JUnit Jupiter API.

```java
package com.example.domain.order;

import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@Tag("unit")
class TestArchitectureVerificationTest {

    @Test
    void shouldVerifyJupiterEngineExecution() {
        // Verifies runtime execution under the Jupiter TestEngine
        String engineName = "JUnit Jupiter 6.x";
        assertNotNull(engineName, "Test execution should run on modern Jupiter engine");
    }
}
```

- [ ] Test execution targets the JUnit Jupiter engine directly
- [ ] Legacy JUnit Vintage engine dependency is excluded unless supporting legacy JUnit 4 tests
- [ ] Build configuration specifies `useJUnitPlatform()` in Gradle or Surefire 3.x in Maven
- [ ] Runtime satisfies Java 17+ baseline requirements
- [ ] Test classes and methods import `org.junit.jupiter.api.*`, avoiding `junit.framework.*` or `org.junit.*`

------


### 2. SUT Identification & The 4 Mental Questions. Scope: Test Conceptualization

Before writing test code, the engineer should define the precise boundary of the **System Under Test (SUT)**. The SUT is the explicit unit, aggregate, service, or policy whose behavior is being verified. Collaborators outside this boundary should be identified as immutable domain values, stateful entities, or external dependencies requiring substitution or real integration.

Every robust test is conceived by answering four cognitive questions:

1. **What am I testing?** The SUT and the specific method, operation, or invariant under examination.
2. **Under what initial conditions?** The exact preconditions, input parameters, baseline state, and stubbed collaborator responses.
3. **What action or stimulus do I execute?** The single command or query applied to the SUT.
4. **What verifiable outcome do I expect?** The expected return value, aggregate state transition, raised domain exception, or outbound contract message.

```java
package com.example.domain.order;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import static org.assertj.core.api.Assertions.assertThat;

class OrderDiscountTest {

    @Test
    void shouldApplyTenPercentDiscountWhenCustomerIsVipAndOrderExceedsThreshold() {
        // 1. What am I testing?
        // SUT: OrderPricingPolicy.calculateEffectiveTotal(Order, CustomerType)

        // 2. Under what initial conditions?
        // Precondition: VIP customer, order subtotal of 200.00 USD, 10% discount policy rule
        CustomerType customerType = CustomerType.VIP;
        Money subtotal = Money.of(new BigDecimal("200.00"), Currency.USD);
        Order order = new Order(OrderId.of("ORD-001"), subtotal);
        OrderPricingPolicy policy = new OrderPricingPolicy();

        // 3. What action or stimulus do I execute?
        Money effectiveTotal = policy.calculateEffectiveTotal(order, customerType);

        // 4. What verifiable outcome do I expect?
        // Postcondition: Subtotal discounted by 10% equals 180.00 USD
        Money expectedTotal = Money.of(new BigDecimal("180.00"), Currency.USD);
        assertThat(effectiveTotal)
            .as("VIP orders exceeding 100 USD should receive a 10% discount")
            .isEqualTo(expectedTotal);
    }
}
```

- [ ] SUT boundary is clearly identified prior to writing test code
- [ ] Preconditions are isolated and contain only data relevant to the scenario
- [ ] Exactly one primary stimulus or action is applied per test execution
- [ ] Observable outcomes verify domain state, return contracts, or invariants
- [ ] The 4 cognitive questions are transparently reflected in the test method arrangement

------


### 3. Test Granularity & Real Integration Testing. Scope: Unit vs Integration, Testcontainers & Build Segregation

A fundamental flaw in testing strategy is presenting "fake" integration tests that run in memory without real infrastructure while labeling them as integration tests. Unit tests and integration tests verify different layers of the software architecture and require distinct tooling and execution lifecycles.

#### Unit Testing: Total Memory Isolation
Unit tests verify domain logic, algorithms, and application use cases in total memory isolation. External dependencies (databases, external REST APIs, message brokers) are substituted with fast in-memory doubles (Fakes, Stubs, or Mocks). Execution takes single-digit milliseconds.

#### Real Integration Testing: Ephemeral Infrastructure with Testcontainers
Integration tests verify that architectural components work correctly together against real infrastructure. Rather than relying on H2 (which masks PostgreSQL-specific features like JSONB, partial indexes, concurrency locks, and sequence generators), modern integration testing relies on **Testcontainers**:

- **Singleton Container Pattern:** Launching and stopping a Docker container per test class incurs high startup overhead (often 5 to 15 seconds per class). The **Singleton Container Pattern** starts the database container once for the entire integration test JVM session, sharing it across all integration test classes while maintaining clean database state between tests.
- **`@Container` + `@Testcontainers` (Lifecycle per Class):** Suitable only when a test requires unique container startup configurations (e.g., custom PostgreSQL flags or custom environment variables).
- **Automated Migrations (Flyway / Liquibase):** Integration tests should run real database migrations against the Testcontainer upon startup to ensure schema compatibility.
- **Database Cleanup Strategies:**
  - **`@Transactional` Rollback:** Rolling back transactions after each test is fast, but it presents real architectural risks: Hibernate flushes may be bypassed, transaction synchronization hooks (`TransactionSynchronization.afterCommit()`) do not trigger, and database constraint violations (e.g., deferred foreign keys or unique constraints checked at commit) are concealed.
  - **Targeted Table Truncation / `@Sql` Cleanup:** Running tests without `@Transactional` and executing a fast truncation script (or a dedicated `DatabaseCleanup` utility) between tests guarantees true persistence semantics, ensuring entities are flushed, committed, and re-read from SQL storage.

#### Spring Data JPA Repository Integration Test

```java
package com.example.infrastructure.persistence;

import com.example.domain.order.Order;
import com.example.domain.order.OrderId;
import com.example.domain.order.OrderStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.dao.DataIntegrityViolationException;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Tag("integration")
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class OrderJpaRepositoryIT extends AbstractPostgresIntegrationTest {

    @Autowired
    private OrderJpaRepository repository;

    @Autowired
    private TestEntityManager entityManager;

    @BeforeEach
    void cleanDatabase() {
        // Explicitly ensuring state isolation between tests
        repository.deleteAllInBatch();
        entityManager.clear();
    }

    @Test
    void shouldPersistAndRetrieveOrderWithGeneratedIdAndTimestamps() {
        // Arrange
        OrderEntity orderEntity = new OrderEntity("CUST-100", new BigDecimal("150.00"), OrderStatus.PENDING);

        // Act: Persist and flush to enforce SQL generation and DB constraints
        OrderEntity saved = repository.saveAndFlush(orderEntity);
        entityManager.clear(); // Clear persistence context to force SQL SELECT on retrieval

        // Assert: Read directly from database
        Optional<OrderEntity> retrieved = repository.findById(saved.getId());
        assertThat(retrieved).isPresent().hasValueSatisfying(entity -> {
            assertThat(entity.getId()).isNotNull();
            assertThat(entity.getCustomerId()).isEqualTo("CUST-100");
            assertThat(entity.getTotalAmount()).isEqualByComparingTo("150.00");
            assertThat(entity.getStatus()).isEqualTo(OrderStatus.PENDING);
            assertThat(entity.getCreatedAt()).isNotNull();
        });
    }

    @Test
    void shouldFailWhenInsertingOrderWithDuplicateUniqueReference() {
        // Arrange
        OrderEntity first = new OrderEntity("CUST-100", new BigDecimal("50.00"), OrderStatus.PENDING);
        first.setReferenceCode("REF-DUPLICATE");
        repository.saveAndFlush(first);

        OrderEntity duplicate = new OrderEntity("CUST-200", new BigDecimal("75.00"), OrderStatus.PENDING);
        duplicate.setReferenceCode("REF-DUPLICATE");

        // Act & Assert: Real database unique constraint must throw DataIntegrityViolationException
        assertThatThrownBy(() -> repository.saveAndFlush(duplicate))
            .isInstanceOf(DataIntegrityViolationException.class);
    }
}
```

#### The Singleton Container Pattern Base Class

```java
package com.example.infrastructure.persistence;

import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;

public abstract class AbstractPostgresIntegrationTest {

    // Singleton container shared across all integration test classes
    protected static final PostgreSQLContainer<?> POSTGRES_CONTAINER;

    static {
        POSTGRES_CONTAINER = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("test_db")
            .withUsername("test_user")
            .withPassword("test_pass");
        POSTGRES_CONTAINER.start();
    }

    @DynamicPropertySource
    static void configureDataSource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES_CONTAINER::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES_CONTAINER::getUsername);
        registry.add("spring.datasource.password", POSTGRES_CONTAINER::getPassword);
        // Ensure Flyway runs migrations against the container
        registry.add("spring.flyway.enabled", () -> "true");
    }
}
```

> [!NOTE]
> **Container Lifecycle vs. Experimental Reuse:**
> - `[JUnit / Testcontainers Fact]:` By default, Testcontainers starts an auxiliary "Ryuk" container that automatically shuts down containers, mapped ports, and volumes when the test JVM process terminates.
> - `[Engineering Recommendation]:` The JVM-level Singleton Container pattern above guarantees that PostgreSQL starts exactly once per test run, avoiding the heavy 5-15s startup penalty per test class.
> - `[Project / Team Policy]:` While Testcontainers supports an experimental reusable containers mode (`.withReuse(true)` paired with `testcontainers.reuse.enable=true` in `~/.testcontainers.properties`) to keep containers alive across JVM restarts for rapid local development, the official Testcontainers documentation explicitly advises that this feature is experimental and **unsuitable for CI pipelines**. Production-grade pipelines should maintain ephemeral, automatically terminated containers as the baseline.

#### Strict Build Separation: Surefire vs. Failsafe

Unit and integration tests should be cleanly partitioned at the build configuration level:

- **Naming Conventions:** Unit test classes end with `Test.java` (e.g., `OrderPricingTest.java`). Integration test classes end with `IT.java` (e.g., `OrderJpaRepositoryIT.java`).
- **Maven Configuration:**
  - **Maven Surefire (`mvn test`):** Executes unit tests matching `**/*Test.java` during the `test` phase. Bypasses slow integration tests.
  - **Maven Failsafe (`mvn verify`):** Executes integration tests matching `**/*IT.java` during the `integration-test` phase and verifies results in `post-integration-test` / `verify`.
- **Gradle Configuration:**
  - Standard `test` task executes unit tests.
  - Dedicated `integrationTest` task compiles `src/integrationTest/java` (or filters `@Tag("integration")`) and executes against real containers.

```xml
<!-- Maven pom.xml configuration snippet -->
<plugins>
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.3.0</version>
        <configuration>
            <includes>
                <include>**/*Test.java</include>
            </includes>
            <excludedGroups>integration</excludedGroups>
        </configuration>
    </plugin>
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-failsafe-plugin</artifactId>
        <version>3.3.0</version>
        <configuration>
            <includes>
                <include>**/*IT.java</include>
            </includes>
            <groups>integration</groups>
        </configuration>
        <executions>
            <execution>
                <goals>
                    <goal>integration-test</goal>
                    <goal>verify</goal>
                </goals>
            </execution>
        </executions>
    </plugin>
</plugins>
```

```kotlin
// Gradle build.gradle.kts snippet
tasks.named<Test>("test") {
    useJUnitPlatform {
        excludeTags("integration")
    }
}

val integrationTest = tasks.register<Test>("integrationTest") {
    description = "Runs integration tests against Testcontainers."
    group = "verification"
    useJUnitPlatform {
        includeTags("integration")
    }
    shouldRunAfter(tasks.named("test"))
}
```

- [ ] Real infrastructure is tested with Testcontainers rather than in-memory mocks like H2
- [ ] Singleton container pattern is leveraged to avoid container restart overhead across test classes
- [ ] Flyway or Liquibase migrations execute automatically against the test container
- [ ] Repository tests verify persistence mappings, ID generation, and constraint violations
- [ ] State cleanup strategy is explicitly defined (table truncation or manual entity deletion)
- [ ] Unit tests (`*Test.java`) run with Surefire / `gradle test`; integration tests (`*IT.java`) run with Failsafe / `gradle integrationTest`
- [ ] Classes are tagged with `@Tag("unit")` or `@Tag("integration")`

------
