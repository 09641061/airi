# Build Integration, CI & Mutation Testing

This reference covers Maven and Gradle execution, unit/integration build separation, coverage, mutation testing, and CI quality gates.

### 19. Build Tool Integration & CLI Execution. Scope: Maven & Gradle CLI

Tests must run reliably from terminal environments and automated pipelines without relying on IDE runners. Both Maven and Gradle provide granular CLI flags to filter test execution.

#### Maven Surefire & Failsafe CLI Execution
- Execute unit tests: `mvn test`
- Execute clean unit tests with tag filter: `mvn test -Dgroups="unit"`
- Execute integration tests via Failsafe: `mvn verify -Dgroups="integration"`
- Execute a single test class: `mvn -Dtest=OrderDiscountTest test`
- Execute a single test method: `mvn -Dtest=OrderDiscountTest#shouldApplyTenPercentDiscountWhenCustomerIsVipAndOrderExceedsThreshold test`
- Execute pattern-matched tests: `mvn -Dtest=Order*Test test`

#### Gradle CLI Execution
- Execute all tests: `./gradlew test`
- Execute specific test class: `./gradlew test --tests "com.example.domain.order.OrderDiscountTest"`
- Execute specific test method: `./gradlew test --tests "com.example.domain.order.OrderDiscountTest.shouldApplyTenPercentDiscountWhenCustomerIsVipAndOrderExceedsThreshold"`
- Execute dedicated integration test task: `./gradlew integrationTest`

```kotlin
// build.gradle.kts configuration for clean CLI integration
tasks.named<Test>("test") {
    useJUnitPlatform {
        includeTags("unit")
        excludeTags("integration")
    }
    testLogging {
        events("passed", "skipped", "failed")
        showExceptions = true
        showCauses = true
        showStackTraces = true
    }
}
```

- [ ] All tests execute reliably via standard Maven and Gradle command-line invocations
- [ ] Specific test classes and individual test methods can be targeted from the CLI
- [ ] Build tools use tags to isolate unit tests from integration tests
- [ ] Runners output clear test results and stack traces during build runs
- [ ] No local IDE-specific configuration is required to execute the test suite

------


### 20. Continuous Integration (CI), Quality Gates & Mutation Testing. Scope: Beyond Coverage Metrics

Continuous Integration guarantees that tests act as enforceable quality gates. However, relying blindly on simplistic metrics creates dangerous false confidence.

#### Code Coverage vs. Test Quality & Mutation Testing (PIT / Pitest)

A major misconception is that achieving 85% or 95% line coverage in JaCoCo guarantees high test quality. **Line coverage measures what code was executed, not what code was verified.** A suite can achieve 95% line coverage with zero assertions by merely invoking methods.

- **`[Engineering Recommendation]` Assertion Effectiveness:** Mutation testing is a strong complementary indicator of assertion effectiveness, not an absolute measure of test quality. Tools like **PIT / Pitest** inject small semantic faults ("mutants") into compiled bytecode—such as inverting conditional boundaries (`<` to `<=`), mutating arithmetic operators (`+` to `-`), or returning `null` instead of values.
- **Killed vs. Survived Mutants:** If your test suite fails when a mutant is introduced, the mutant is **killed** (success). If the tests continue to pass despite the mutant, the mutant **survived** (identifying a potential gap in assertion coverage).
- **The Reality of Equivalent Mutants `[Engineering Recommendation]`:** Not every surviving mutant represents a defect in your test suite. An **equivalent mutant** is a bytecode mutation that produces syntax changes that are semantically identical to the original behavior (e.g., changing an internal loop index optimization or an unreachable defensive condition). Because observable behavior does not change, no test can ever kill an equivalent mutant.
- **Execution Cadence & Scoping `[Engineering Recommendation]`:** Mutation testing runs tests repeatedly for hundreds of mutants, incurring substantial CPU overhead. Rather than running PIT across an entire multi-module monolith on every pull request, scope mutation testing to core domain and application packages, or schedule full runs as asynchronous nightly quality gates.
- **Configurable Quality Gates `[Project / Team Policy]`:** The threshold below (`<mutationThreshold>80</mutationThreshold>`) represents an example project-level quality gate, not a universal mandate. Teams calibrate threshold targets based on package criticality, excluding generated code, DTOs, and framework configuration classes.

```xml
<!-- Sample Pitest Maven Plugin Configuration (Illustrative Team Policy) -->
<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
    <version>1.16.0</version>
    <dependencies>
        <dependency>
            <groupId>org.pitest</groupId>
            <artifactId>pitest-junit5-plugin</artifactId>
            <version>1.2.1</version>
        </dependency>
    </dependencies>
    <configuration>
        <targetClasses>
            <param>com.example.domain.*</param>
            <param>com.example.application.*</param>
        </targetClasses>
        <targetTests>
            <param>com.example.*Test</param>
        </targetTests>
        <!-- Illustrative team threshold example; adjust per package criticality -->
        <mutationThreshold>80</mutationThreshold>
    </configuration>
</plugin>
```

#### Fail-Fast in CI: A Situational Decision
Recommending `--fail-fast` as an absolute rule in CI is flawed. Evaluate the trade-off:
- **Use Fail-Fast (`--fail-fast` / `-Dsurefire.skipAfterFailureCount=1`):** Ideal for local development, pre-commit hooks, and short feedback loops where developers want immediate notification of the first failure to fix it immediately.
- **Run Full Suite Execution in Centralized CI:** In centralized CI pull request pipelines, executing the entire suite is usually preferable. If a change breaks 15 tests across 4 modules, reporting all 15 failures in a single run allows the engineer to address all regressions at once, rather than iterating through 15 sequential pipeline runs.

- [ ] Pull request pipelines execute automated tests and enforce quality gates
- [ ] JaCoCo line coverage is used to detect unexercised code, not as proof of test quality
- [ ] Mutation testing (PIT) is integrated on core domain packages to verify assertion strength
- [ ] Fail-fast is used for local pre-commit checks; full suite runs are used in centralized CI for batch diagnostics
- [ ] Orphaned `@Disabled` tests lacking ticket references are rejected by quality gates

------
