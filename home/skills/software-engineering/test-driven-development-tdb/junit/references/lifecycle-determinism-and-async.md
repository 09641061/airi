# Lifecycle, Determinism, Concurrency & Async Tests

This reference covers timeouts, assumptions, fixture lifecycle, parallel execution, deterministic clocks, asynchronous verification, JUnit parameter resolution, and filesystem boundaries.

### 8. Execution Time, Timeouts & Asynchronous Verification. Scope: CI Hang Protection vs. Flakiness

Uncontrolled execution time is a primary cause of blocked CI pipelines. JUnit Jupiter provides both declarative annotations and programmatic assertions to establish timeout boundaries.

#### Timeouts as Safeguards, Not Micro-Benchmarks
Timeouts in JUnit should be treated as **safeguards against deadlocks, unhandled network timeouts, and infinite loops**, rather than statistical performance benchmarks. Setting arbitrarily aggressive timeouts (e.g., `< 50ms` or `< 1000ms`) on complex integration tests creates flaky test runs when running on resource-constrained or virtualized CI runners subject to CPU throttling and noisy neighbors. Formal performance benchmarking belongs in dedicated harnesses such as **JMH (Java Microbenchmark Harness)**.

#### The Hazards of `assertTimeoutPreemptively`
- `assertTimeout(Duration, Executable)` executes the test logic in the **same thread**, waiting for completion before evaluating elapsed time. This is safe for thread-bound contexts.
- `assertTimeoutPreemptively(Duration, Executable)` executes the code in a **separate worker thread**, interrupting it if the threshold is exceeded.
  - **Severe Danger:** Because it executes in a separate thread, `assertTimeoutPreemptively` breaks `ThreadLocal` context propagation. Spring's `SecurityContextHolder`, transaction managers (`@Transactional` test rollbacks), and Hibernate persistence contexts become detached or corrupted, leading to intermittent and confusing errors.

#### Asynchronous Verification with Awaitility
When testing asynchronous systems (e.g., background message consumers, scheduled jobs, event listeners), avoid `Thread.sleep()`. Use **Awaitility** to poll condition predicates with deterministic timeouts and intervals:

```java
package com.example.domain.order;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;
import java.time.Duration;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

class AsyncOrderProcessingTest {

    @Test
    @Timeout(value = 5, unit = TimeUnit.SECONDS) // Pipeline hang protection
    void shouldProcessOrderAsynchronouslyWithinTolerantBoundary() {
        OrderNotificationListener listener = new OrderNotificationListener();
        OrderEventPublisher publisher = new OrderEventPublisher(listener);

        publisher.publishOrderPlaced(OrderId.of("ORD-200"));

        // Awaitility poll replaces arbitrary Thread.sleep()
        await()
            .atMost(Duration.ofSeconds(3))
            .pollInterval(Duration.ofMillis(100))
            .untilAsserted(() -> assertThat(listener.wasNotified(OrderId.of("ORD-200"))).isTrue());
    }
}
```

- [ ] Timeouts protect CI pipelines against deadlocks and hangs, not fine-grained performance benchmarking
- [ ] Arbitrarily tight timeouts that induce flakiness in virtualized CI environments are avoided
- [ ] `assertTimeout` or declarative `@Timeout` is preferred over `assertTimeoutPreemptively`
- [ ] `assertTimeoutPreemptively` is avoided when tests depend on `ThreadLocal`, transactions, or JPA sessions
- [ ] Asynchronous event testing utilizes Awaitility rather than `Thread.sleep()`

------


### 9. Assumptions & Conditional Execution. Scope: Aborted vs. Failed Tests

Tests occasionally depend on dynamic environmental preconditions—such as a specific operating system, the presence of an active Docker daemon, or specific environment variables. When a precondition is not satisfied, the test should abort gracefully rather than failing the build.

- **Dynamic Assumptions (`Assumptions.*`):** `assumeTrue()`, `assumeFalse()`, and `assumingThat()`. If an assumption evaluates to false, JUnit throws `org.opentest4j.TestAbortedException`.
- **Test Lifecycle States in CI Reports:**
  - **Passed (Green):** Test executed and all assertions succeeded.
  - **Failed (Red):** The SUT produced unexpected behavior or threw an unhandled exception (`AssertionError`). Indicates a code defect.
  - **Aborted / Skipped (Yellow):** An environmental assumption was not satisfied (`TestAbortedException`). The build remains green.
  - **Disabled (Gray):** Test was statically marked with `@Disabled`.
- **Rule of Thumb:** Use assumptions exclusively for environmental prerequisites, never for validating SUT domain logic or expected business invariants.

```java
package com.example.infrastructure;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.junit.jupiter.api.Assumptions.assumingThat;

class EnvironmentalConditionTest {

    @Test
    @DisplayName("Should execute external gateway smoke test only when staging credentials exist")
    void shouldExecuteExternalGatewaySmokeTestOnlyWhenStagingCredentialsExist() {
        String apiKey = System.getenv("STAGING_GATEWAY_API_KEY");
        
        // Aborts cleanly without failing the CI pipeline if credentials are not configured locally
        assumeTrue(apiKey != null && !apiKey.isBlank(), "Aborted: STAGING_GATEWAY_API_KEY is not configured");

        GatewayClient client = new GatewayClient(apiKey);
        assertThat(client.ping()).isTrue();
    }

    @Test
    @DisplayName("Should execute POSIX filesystem permission tests only on Unix-like environments")
    void shouldExecutePosixFilesystemPermissionTestsOnlyOnUnixLikeEnvironments() {
        String os = System.getProperty("os.name").toLowerCase();

        assumingThat(os.contains("linux") || os.contains("mac"), () -> {
            // Evaluated only on Linux or macOS
            PosixPermissionChecker checker = new PosixPermissionChecker();
            assertThat(checker.isPosixSupported()).isTrue();
        });

        // Test continues unconditionally for common assertions
        assertThat(System.currentTimeMillis()).isPositive();
    }
}
```

- [ ] Assumptions are used for environmental preconditions, never for SUT business logic
- [ ] Failed assumptions mark tests as aborted/skipped, preserving CI pipeline green status
- [ ] Meaningful diagnostic messages are included in all `assume*` invocations
- [ ] `assumingThat` is used to execute platform-specific logic without aborting the enclosing test
- [ ] Business rule violations rely on `assertThat` / `assert*`, never `assume*`

------


### 10. Test Lifecycle & Fixture Management: Debunking Cargo Cults. Scope: Lifecycle Management

Managing test fixtures (the baseline state and collaborators required for testing) requires understanding JUnit Jupiter's instance lifecycles and avoiding superstitious anti-patterns.

#### Default Instantiation Mode: `@TestInstance(Lifecycle.PER_METHOD)`
By default, JUnit Jupiter creates a **new instance of the test class for each test method**. This guarantees isolation: instance fields modified in Test A do not exist in the instance used by Test B.

#### Debunking the Cargo Cult: Setting Fields to `null` in `@AfterEach`
A frequent anti-pattern seen in test code is assigning instance variables to `null` inside `@AfterEach`:
```java
// CARGO CULT ANTI-PATTERN: Completely useless under PER_METHOD
@AfterEach
void tearDown() {
    this.order = null;
    this.pricingPolicy = null;
}
```
**Why this is unnecessary:** Because JUnit instantiates a brand new test class instance for every single `@Test` method under the default `PER_METHOD` lifecycle, the previous test instance is immediately dereferenced and eligible for JVM garbage collection as soon as the test method finishes. Explicitly setting references to `null` accomplishes nothing except adding visual clutter.

#### What `@AfterEach` Is Actually For:
`@AfterEach` should be used to clean up external state that survives beyond the JVM object boundary:
- Resetting modified System Properties or Environment variables (`System.clearProperty(...)`).
- Clearing `SecurityContextHolder.clearContext()` to prevent user credentials from leaking into subsequent tests on the same thread.
- Closing open I/O streams, network sockets, or client handles not managed by automatic extensions.
- Resetting shared static caches or thread-local storage.

#### Safe Use of `@TestInstance(Lifecycle.PER_CLASS)`
In `PER_CLASS` mode, JUnit reuses a single test class instance across all test methods in that class. This allows non-static `@BeforeAll` and `@AfterAll` methods.
- **When to use:** Managing expensive, shared, read-only external resources (such as starting a heavy Testcontainers instance or loading an immutable multi-megabyte dataset).
- **Warning:** In `PER_CLASS` mode, mutable instance fields are shared across tests. State mutations in one test can bleed into others unless explicitly reset.

```java
package com.example.domain.order;

import org.junit.jupiter.api.*;
import java.math.BigDecimal;
import static org.assertj.core.api.Assertions.assertThat;

@TestInstance(TestInstance.Lifecycle.PER_METHOD)
class OrderLifecycleManagementTest {

    private OrderPricingPolicy pricingPolicy;
    private Order draftOrder;

    @BeforeEach
    void setUp() {
        // Pristine, isolated fixture instantiated before each test method
        pricingPolicy = new OrderPricingPolicy();
        draftOrder = Order.createDraft(OrderId.of("ORD-001"));
    }

    @AfterEach
    void tearDownExternalResources() {
        // Legitimate cleanup: ThreadLocal or security context reset
        // Setting draftOrder = null is omitted because PER_METHOD discards this instance
        SecurityContextHolder.clearContext();
    }

    @Test
    void shouldCalculateZeroTotalForEmptyDraftOrder() {
        Money total = pricingPolicy.calculateEffectiveTotal(draftOrder, CustomerType.REGULAR);
        assertThat(total.amount()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    void shouldCalculateTotalWhenItemIsAddedToDraftOrder() {
        draftOrder.addItem(new OrderItem(ProductId.of("P-1"), Quantity.of(1), Money.of(new BigDecimal("50.00"), Currency.USD)));
        Money total = pricingPolicy.calculateEffectiveTotal(draftOrder, CustomerType.REGULAR);
        assertThat(total.amount()).isEqualByComparingTo(new BigDecimal("50.00"));
    }
}
```

- [ ] `Lifecycle.PER_METHOD` remains the default lifecycle for isolated testing
- [ ] Superstitious setting of fields to `null` in `@AfterEach` is eradicated
- [ ] `@AfterEach` is reserved for true cleanup: ThreadLocals, security contexts, open streams
- [ ] `@TestInstance(Lifecycle.PER_CLASS)` is reserved for shared, read-only, heavy fixtures
- [ ] Test fixtures are constructed fresh in `@BeforeEach` to guarantee isolation

------


### 11. Determinism, Order Independence, and Concurrency. Scope: `@ResourceLock` & Parallel Execution

A test suite must be **deterministic**: running 1,000 times in any order or in parallel must yield identical results every time.

#### Order Independence vs. Parallelization Concurrency
A test class can be completely independent of execution order when run sequentially, yet **fail intermittently when executed in parallel**.
- **Order-dependent failure:** Test B fails when run alone (`mvn test -Dtest=OrderTest#testB`) because it depends on Test A running first to populate shared state.
- **Concurrency failure:** Test A and Test B run at the exact same moment on different threads. Both pass in isolation, but they collide on a shared resource (e.g., competing for a fixed TCP port, writing to the same filesystem path, modifying `System.setProperty()`, or altering the same database table).

#### Parallel Test Execution with `@Execution` and `@ResourceLock`
JUnit Jupiter supports parallel test execution via configuration (`junit.jupiter.execution.parallel.enabled = true`). When running concurrently, shared resources must be synchronized using `@ResourceLock`:

```java
package com.example.infrastructure;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.parallel.Execution;
import org.junit.jupiter.api.parallel.ExecutionMode;
import org.junit.jupiter.api.parallel.ResourceAccessMode;
import org.junit.jupiter.api.parallel.ResourceLock;
import org.junit.jupiter.api.parallel.Resources;

import static org.assertj.core.api.Assertions.assertThat;

@Execution(ExecutionMode.CONCURRENT)
class SystemPropertyAccessTest {

    @Test
    @ResourceLock(value = Resources.SYSTEM_PROPERTIES, mode = ResourceAccessMode.READ)
    void shouldReadSystemPropertySafely() {
        String javaVersion = System.getProperty("java.version");
        assertThat(javaVersion).isNotNull();
    }

    @Test
    @ResourceLock(value = Resources.SYSTEM_PROPERTIES, mode = ResourceAccessMode.READ_WRITE)
    void shouldModifySystemPropertyWithExclusiveLock() {
        String key = "custom.feature.flag";
        System.setProperty(key, "true");
        try {
            assertThat(System.getProperty(key)).isEqualTo("true");
        } finally {
            System.clearProperty(key);
        }
    }
}
```

#### Deterministic Time Handling via `Clock.fixed()` `[Engineering Recommendation]`
Domain logic that checks expirations, discounts, or timestamps should avoid relying on unmocked global system clocks (such as `Instant.now()` or `System.currentTimeMillis()`). Instead, inject `java.time.Clock` into domain services and entities. In tests, supply `Clock.fixed(Instant, ZoneId)` to freeze time deterministically without external dependencies.

```java
package com.example.domain.order;

import org.junit.jupiter.api.Test;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import static org.assertj.core.api.Assertions.assertThat;

class OrderExpirationTest {

    private static final Instant FROZEN_NOW = Instant.parse("2026-09-21T10:00:00Z");
    private final Clock fixedClock = Clock.fixed(FROZEN_NOW, ZoneOffset.UTC);

    @Test
    void shouldIdentifyOrderAsExpiredWhenPlacedBeyondGracePeriod() {
        // Arrange: Placed 25 hours before frozen reference time
        Instant placedAt = FROZEN_NOW.minus(Duration.ofHours(25));
        Order order = new Order(OrderId.of("ORD-1"), OrderStatus.PENDING, placedAt);

        // Act
        boolean expired = order.isExpired(fixedClock, Duration.ofHours(24));

        // Assert
        assertThat(expired).isTrue();
    }
}
```

#### Eliminating Flakiness in Asynchronous Code `[Engineering Recommendation]`
Avoid arbitrary `Thread.sleep()` calls to wait for asynchronous events, message consumption, or background processing. Fixed delays waste pipeline time when too generous, and cause intermittent test failures ("flakiness") when CI runner CPU throttling slows execution down. Prefer explicit polling mechanisms like **Awaitility**:
```java
org.awaitility.Awaitility.await()
    .atMost(Duration.ofSeconds(5))
    .untilAsserted(() -> assertThat(orderRepository.findById(orderId)).isPresent());
```

- [ ] Tests execute deterministically regardless of execution order or parallel threads
- [ ] Shared global resources (System Properties, time, files) are protected with `@ResourceLock`
- [ ] Arbitrary `Thread.sleep()` is avoided in favor of Awaitility polling or deterministic time controls
- [ ] Time-dependent domain logic relies on an injected `java.time.Clock`
- [ ] Date formatting and conversions enforce explicit timezones (e.g., `UTC`) and locales

------


### 15. JUnit Dependency Injection & Filesystem Boundary Testing. Scope: `ParameterResolver`, `@TempDir` & Test Granularity

Unlike earlier iterations where test methods were strictly parameterless, JUnit Jupiter features an extensible dependency injection mechanism powered by the `ParameterResolver` SPI.

- **Native JUnit Resolvers `[JUnit Fact]`:**
  - `TestInfo`: Injects metadata regarding the current test execution (display name, test class, test method, tags).
  - `TestReporter`: Injects an abstraction to publish structured key-value entries into build reports (Surefire/Failsafe XML), replacing raw `System.out.println`.
- **Filesystem Safety with `@TempDir` `[JUnit Fact]`:**
  - `@TempDir` injects an ephemeral `java.nio.file.Path` or `java.io.File`. JUnit guarantees fresh directory provisioning and automatic recursive deletion upon test completion, even when assertions fail.
  - Can be placed on method parameters (isolated directory per test method) or on class fields (shared temporary directory for the class).

#### Pure Unit Test vs. Filesystem Component Test `[Engineering Recommendation]`

A common contradiction in test design is declaring a test to be a pure unit test ("zero disk I/O") while invoking `Files.write()` or `Files.readAllLines()` inside an `@TempDir`. A clear architectural boundary resolves this:

1. **Pure Unit Test (`@Tag("unit")`):** Verifies formatting, encoding, and serialization logic completely in memory using abstractions such as `Writer`, `OutputStream`, or returning string representations. Zero filesystem access.
2. **Filesystem Component Test (`@Tag("component")` or `@Tag("integration")`):** Verifies physical file operations against the operating system (permissions, directory creation, flushing, disk I/O). Uses `@TempDir` to guarantee isolation and prevent filesystem pollution.

```java
package com.example.infrastructure.export;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInfo;
import org.junit.jupiter.api.TestReporter;
import org.junit.jupiter.api.io.TempDir;
import java.io.IOException;
import java.io.StringWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

// 1. Pure Unit Test: 100% in-memory verification of CSV formatting logic
@Tag("unit")
class OrderCsvFormatterTest {

    @Test
    @DisplayName("Should format order lines into CSV string in memory without disk I/O")
    void shouldFormatOrderLinesInMemory() throws IOException {
        OrderCsvFormatter formatter = new OrderCsvFormatter();
        StringWriter writer = new StringWriter();

        formatter.writeLines(writer, List.of("Widget,2,20.00"));

        assertThat(writer.toString()).isEqualTo("Item,Qty,Price\nWidget,2,20.00\n");
    }
}

// 2. Filesystem Component Test: Verifies physical disk writing and OS integration
@Tag("component")
class OrderCsvFileExporterIT {

    @Test
    @DisplayName("Should physically write CSV file to ephemeral disk directory")
    void shouldWriteCsvFileToDisk(
        @TempDir Path tempDir,
        TestInfo testInfo,
        TestReporter testReporter) throws IOException {

        testReporter.publishEntry("Executing", testInfo.getDisplayName());
        Path targetFile = tempDir.resolve("invoice.csv");
        OrderCsvFileExporter exporter = new OrderCsvFileExporter();

        // Act: Physical disk I/O executed against the injected temporary directory
        exporter.exportToFile(targetFile, List.of("Widget,2,20.00"));

        // Assert: Physical verification on disk
        assertThat(Files.exists(targetFile)).isTrue();
        List<String> writtenLines = Files.readAllLines(targetFile);
        assertThat(writtenLines).contains("Widget,2,20.00");
    }
}
```

- [ ] In-memory serialization and formatting logic is tested with `@Tag("unit")` without filesystem I/O
- [ ] Physical file writing is classified as `@Tag("component")` or `@Tag("integration")`
- [ ] Ephemeral filesystem testing relies on `@TempDir` instead of hardcoded paths (e.g., `/tmp/test.csv`)
- [ ] `TestInfo` and `TestReporter` replace manual `System.out.println` console logging
- [ ] Temporary directories are scoped at the method level by default for strict isolation

------
