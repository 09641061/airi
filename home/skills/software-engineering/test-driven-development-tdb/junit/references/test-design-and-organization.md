# Test Design, Naming & Organization

This reference covers test anatomy, executable specifications, boundary analysis, parameterized tests, nested contexts, and contract-focused verification.

### 4. Test Anatomy: AAA, Given-When-Then, and Fluent Variations. Scope: Method Structure

Every test method benefits from a clear, predictable structure: **Arrange-Act-Assert (AAA)** or its Behavior-Driven Development equivalent, **Given-When-Then**.

- **Arrange (Given):** Set up the SUT, configure input arguments, establish domain preconditions, and configure required test doubles.
- **Act (When):** Trigger the single stimulus, command, or query being tested. Ideally a single method invocation.
- **Assert (Then):** Verify the observable outcome, returned value, aggregate state modification, or emitted domain event.

#### Engineering Heuristic: When to Use Explicit AAA Comments
Rigidly enforcing three AAA comments in every single test method regardless of size is dogmatic. Apply this heuristic:
- **Use explicit `// Arrange`, `// Act`, `// Assert` comments** when the test involves non-trivial setup, multiple local variables, or collaborator configuration where visual separation enhances cognitive clarity.
- **Omit comments for self-evident single-line or fluent assertions:** When testing pure functions, mappings, or simple value objects, a 2-line or 3-line test does not require boilerplate comments:
  ```java
  @Test
  void shouldNormalizePostalCodeByRemovingWhitespace() {
      PostalCode postalCode = PostalCode.of(" W1A   1AA ");
      assertThat(postalCode.value()).isEqualTo("W1A1AA");
  }
  ```

#### Multi-Assertion Cohesion
Validating a single business behavior often requires asserting multiple attributes of the resulting state (e.g., verifying that confirming an order updates status, records a timestamp, and increments sequence). This is valid and cohesive. What should generally be avoided is chaining multiple sequential operations (Act-Assert-Act-Assert) within a single unit test.

```java
package com.example.domain.order;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import static org.assertj.core.api.Assertions.assertThat;

class OrderSubmissionTest {

    @Test
    void shouldTransitionToSubmittedStateWhenOrderContainsValidItems() {
        // Arrange
        OrderId orderId = OrderId.of("ORD-500");
        Order order = Order.createDraft(orderId);
        OrderItem item = new OrderItem(ProductId.of("PROD-1"), Quantity.of(2), Money.of(new BigDecimal("25.00"), Currency.USD));
        order.addItem(item);

        // Act
        order.submit();

        // Assert: Cohesive multi-attribute verification of the submission outcome
        assertThat(order.getStatus()).isEqualTo(OrderStatus.SUBMITTED);
        assertThat(order.getItems()).hasSize(1);
    }
}
```

- [ ] Tests clearly distinguish Arrange, Act, and Assert stages
- [ ] Act stage focuses on a single primary method invocation
- [ ] Assertions verify outcomes belonging strictly to the behavior executed in Act
- [ ] Concise tests avoid unnecessary comment boilerplate when intent is visually self-evident
- [ ] Sequential Act-Assert-Act-Assert chains in unit tests are refactored into distinct test methods

------


### 5. Descriptive Naming & Display Strategy. Scope: Living Documentation

Test method names serve as executable specifications and should convey domain intent without requiring an engineer to inspect implementation code when a failure occurs in CI.

- **Recommended Naming Conventions `[Engineering Recommendation]`:**
  - `should[ExpectedBehavior]When[Condition]` (e.g., `shouldApplyDiscountWhenCustomerIsVip`)
  - `[methodUnderTest]_[scenario]_[expectedResult]` (e.g., `calculateTotal_withVipDiscount_returnsDiscountedAmount`)
- **`@DisplayName` Annotation `[JUnit Fact]`:** Provides human-readable, domain-focused sentences for test runners and living documentation. Useful when business stakeholders or QA leads review test reports.
- **`@DisplayNameGeneration` `[JUnit Fact]`:** Allows class-level declarative formatting (e.g., `DisplayNameGenerator.ReplaceUnderscores.class`), removing the need for manual `@DisplayName` on every method.
- **Disciplined Test Suppression with `@Disabled`:**
  - `[JUnit Fact]:` `@Disabled` signals to the test engine that a method or class container should be skipped during discovery/execution without failing the build. It takes an optional string reason.
  - `[Project / Team Policy]:` Tests should not be silently disabled without accountability. A recommended team policy requires every `@Disabled` annotation to cite an active issue tracker reference (e.g., `@Disabled("Blocked by TAX-402 pending updated VAT rate tables")`), preventing disabled tests from turning into forgotten zombie code.

```java
package com.example.domain.order;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("Order Aggregate Lifecycle Specifications")
class OrderLifecycleNamingTest {

    @Test
    @DisplayName("Should transition order status to CANCELLED when cancellation is requested on a PENDING order")
    void shouldTransitionToCancelledWhenCancellationRequestedOnPendingOrder() {
        Order order = Order.createDraft(OrderId.of("ORD-101"));

        order.cancel(CancellationReason.CUSTOMER_REQUEST);

        assertThat(order.getStatus()).isEqualTo(OrderStatus.CANCELLED);
    }

    @Test
    @Disabled("Blocked by PAY-882: Awaiting third-party mock sandbox upgrade")
    @DisplayName("Should trigger automatic refund when paid order is cancelled within cooling-off window")
    void shouldTriggerAutomaticRefundWhenPaidOrderIsCancelledWithinCoolingOffWindow() {
        // Pending external sandbox implementation
    }
}
```

- [ ] Test method names clearly communicate expected behavior and scenario conditions
- [ ] Generic names like `testOrder()`, `check()`, or `runScenario()` are avoided
- [ ] `@DisplayName` describes business intent rather than raw method signatures
- [ ] Every `@Disabled` test includes a ticket identifier and documented reason
- [ ] Failure reports clearly indicate which business capability failed

------


### 12. Equivalence Partitioning & Boundary Value Analysis. Scope: Boundary Analysis

High-quality testing avoids both incomplete ad-hoc coverage and redundant brute-force test generation. It applies **Equivalence Partitioning (EP)** and **Boundary Value Analysis (BVA)** to verify representative input classes and boundary transitions.

- **Equivalence Partitioning:** Divide input domains into valid and invalid partitions where the SUT is expected to process all members identically. One representative test exercises the partition.
- **Boundary Value Analysis:** Defects cluster disproportionately at partition boundaries. For an inclusive range `min <= x <= max`, verify:
  - **Lower Boundary:** `min - 1` (invalid), `min` (valid boundary), `min + 1` (valid internal).
  - **Upper Boundary:** `max - 1` (valid internal), `max` (valid boundary), `max + 1` (invalid).
- **Categorization:**
  - **Happy Path:** Nominal valid input.
  - **Boundary Values:** Extreme valid and invalid transition points.
  - **Edge & Corner Cases:** Zero, negative numbers, empty strings, strings containing only whitespace, `null`, numeric limits (`Integer.MAX_VALUE`), and leap years.

```java
package com.example.domain.order;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("Order Quantity Boundary Value Analysis")
class QuantityBoundaryTest {

    // Invariant: Quantity must be between 1 and 100 inclusive.

    @Test
    @DisplayName("Nominal: Value within valid range (50) is accepted")
    void shouldCreateQuantityWhenValueIsNominal() {
        Quantity quantity = Quantity.of(50);
        assertThat(quantity.value()).isEqualTo(50);
    }

    @Test
    @DisplayName("Lower Bound: Minimum allowed value (1) is accepted")
    void shouldCreateQuantityWhenValueIsLowerBound() {
        Quantity quantity = Quantity.of(1);
        assertThat(quantity.value()).isEqualTo(1);
    }

    @Test
    @DisplayName("Upper Bound: Maximum allowed value (100) is accepted")
    void shouldCreateQuantityWhenValueIsUpperBound() {
        Quantity quantity = Quantity.of(100);
        assertThat(quantity.value()).isEqualTo(100);
    }

    @Test
    @DisplayName("Invalid Lower Bound: Value just below minimum (0) is rejected")
    void shouldThrowExceptionWhenValueIsJustBelowLowerBound() {
        assertThatThrownBy(() -> Quantity.of(0))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("Quantity must be at least 1");
    }

    @Test
    @DisplayName("Invalid Upper Bound: Value just above maximum (101) is rejected")
    void shouldThrowExceptionWhenValueIsJustAboveUpperBound() {
        assertThatThrownBy(() -> Quantity.of(101))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("Quantity cannot exceed 100");
    }

    @Test
    @DisplayName("Edge Case: Negative quantity is rejected")
    void shouldThrowExceptionWhenValueIsNegative() {
        assertThatThrownBy(() -> Quantity.of(-1))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
```

- [ ] Input domains are mapped into valid and invalid equivalence partitions
- [ ] Boundary values (`boundary - 1`, `boundary`, `boundary + 1`) are explicitly covered
- [ ] Happy path tests verify nominal business operation
- [ ] Negative tests verify that invalid inputs trigger domain validation errors
- [ ] Edge cases (`null`, empty string, negative numbers, overflows) have dedicated tests

------


### 13. Parameterized & Data-Driven Testing. Scope: `@ParameterizedTest` & Sources

When the same assertion logic must be verified against multiple input sets and expected outputs, writing multiple repetitive `@Test` methods duplicates code and obscures domain rules. JUnit Jupiter provides `@ParameterizedTest` to decouple the test algorithm from test data.

- **Isolated Execution Lifecycle:** Each parameter invocation in a `@ParameterizedTest` is executed as a distinct test node with its own isolated `@BeforeEach` and `@AfterEach` lifecycle.
- **Data Sources:**
  - `@ValueSource`: Primitives and Strings (`strings = {"a", "b"}`, `ints = {1, 2}`).
  - `@NullSource`, `@EmptySource`, `@NullAndEmptySource`: Injects `null` and empty strings or collections.
  - `@EnumSource`: Passes enum constants with optional inclusion/exclusion filters.
  - `@CsvSource`: Inline comma-separated tabular values, supporting multi-parameter arguments.
  - `@CsvFileSource`: External CSV files for large, business-driven tabular specifications.
  - `@MethodSource`: References a static method returning `Stream<Arguments>` for complex domain object graphs.
- **Custom Display Formatting:** Use the `name` attribute to provide clear test runner output: `name = "[{index}] input={0}, expected={1}"`.

```java
package com.example.domain.order;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ParameterizedDiscountTest {

    @ParameterizedTest(name = "[{index}] Subtotal {0} with tier {1} yields discount {2}")
    @CsvSource({
        "50.00,  REGULAR, 0.00",
        "150.00, REGULAR, 7.50",
        "50.00,  VIP,     5.00",
        "150.00, VIP,     22.50"
    })
    void shouldCalculateExpectedDiscountAcrossCustomerTiers(
        BigDecimal subtotal, CustomerType tier, BigDecimal expectedDiscount) {

        OrderPricingPolicy policy = new OrderPricingPolicy();
        Order order = new Order(OrderId.of("ORD-1"), Money.of(subtotal, Currency.USD));

        Money discount = policy.calculateDiscount(order, tier);

        assertThat(discount.amount()).isEqualByComparingTo(expectedDiscount);
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"   ", "\t", "\n"})
    void shouldRejectInvalidOrderReferenceCodes(String invalidCode) {
        assertThatThrownBy(() -> new OrderReference(invalidCode))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @ParameterizedTest
    @EnumSource(value = OrderStatus.class, names = {"CANCELLED", "REFUNDED"})
    void shouldDisallowModificationForTerminalStatuses(OrderStatus terminalStatus) {
        Order order = new Order(OrderId.of("ORD-1"), terminalStatus);
        assertThat(order.canBeModified()).isFalse();
    }

    @ParameterizedTest
    @MethodSource("provideOrderScenarios")
    void shouldVerifyComplexOrderScenarios(Order order, boolean expectedValidity) {
        assertThat(order.isValid()).isEqualTo(expectedValidity);
    }

    static Stream<Arguments> provideOrderScenarios() {
        return Stream.of(
            Arguments.of(Order.createDraft(OrderId.of("ORD-1")), false),
            Arguments.of(Order.createWithItems(OrderId.of("ORD-2"), List.of(
                new OrderItem(ProductId.of("P-1"), Quantity.of(1), Money.of(BigDecimal.TEN, Currency.USD))
            )), true)
        );
    }
}
```

- [ ] Repetitive test logic is consolidated into parameterized tests
- [ ] Inputs and expected outputs are organized cleanly via `@CsvSource` or `@MethodSource`
- [ ] `@NullAndEmptySource` verifies robustness against malformed input
- [ ] Custom `name` formats dynamic reports in IDE and CI output
- [ ] Complex object arguments are provisioned via typed `Stream<Arguments>`

------


### 16. Hierarchical Test Organization. Scope: BDD Scenarios with `@Nested`

Complex domain aggregates feature contextual, state-dependent behaviors. A flat test class with thirty methods obscures how behavior transitions as aggregate state changes. JUnit Jupiter solves this with `@Nested`.

- **Hierarchical Contexts:** Inner classes annotated with `@Nested` group tests by state context.
- **BDD Mapping:**
  - Outer class: `Given [Initial Context / Aggregate Baseline]`
  - Nested class: `When [State Transition / Stimulus]`
  - Test methods: `Then [Observable Invariant / Output]`
- **Fixture Inheritance:** Inner `@Nested` classes automatically execute the outer class's `@BeforeEach` methods before their own `@BeforeEach` methods execute, forming a clean cascade of state setup.

```java
package com.example.domain.order;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("Given an Order Aggregate")
class OrderNestedBddTest {

    private Order order;

    @BeforeEach
    void setUp() {
        order = Order.createDraft(OrderId.of("ORD-001"));
    }

    @Nested
    @DisplayName("When the order is in DRAFT state")
    class WhenOrderIsDraft {

        @Test
        @DisplayName("Then items can be added freely")
        void shouldAllowAddingItems() {
            OrderItem item = new OrderItem(ProductId.of("P-1"), Quantity.of(1), Money.of(BigDecimal.TEN, Currency.USD));
            order.addItem(item);
            assertThat(order.getItems()).hasSize(1);
        }

        @Test
        @DisplayName("Then cancellation transitions status directly to CANCELLED")
        void shouldAllowCancellation() {
            order.cancel(CancellationReason.CUSTOMER_REQUEST);
            assertThat(order.getStatus()).isEqualTo(OrderStatus.CANCELLED);
        }
    }

    @Nested
    @DisplayName("When the order is already SUBMITTED")
    class WhenOrderIsSubmitted {

        @BeforeEach
        void transitionToSubmitted() {
            order.addItem(new OrderItem(ProductId.of("P-1"), Quantity.of(1), Money.of(BigDecimal.TEN, Currency.USD)));
            order.submit();
        }

        @Test
        @DisplayName("Then adding new items must be rejected")
        void shouldRejectAddingItemsWhenSubmitted() {
            OrderItem item = new OrderItem(ProductId.of("P-2"), Quantity.of(2), Money.of(BigDecimal.TEN, Currency.USD));
            
            assertThatThrownBy(() -> order.addItem(item))
                .isInstanceOf(IllegalStateException.class);
        }

        @Test
        @DisplayName("Then subsequent submission must be rejected as invalid state transition")
        void shouldRejectSubsequentSubmission() {
            assertThatThrownBy(() -> order.submit())
                .isInstanceOf(IllegalStateException.class);
        }
    }
}
```

- [ ] `@Nested` inner classes model distinct aggregate states or business contexts
- [ ] Context naming maps naturally to BDD Given-When-Then hierarchies
- [ ] Fixture setup cascades logically from parent to nested contexts
- [ ] Test discovery displays readable, hierarchical trees in IDEs and CI tools
- [ ] Contextual duplication across test classes is minimized

------


### 17. Contract-Based Testing vs. Implementation Coupling. Scope: Refactoring Resilience

Tests that know too much about *how* code is implemented are fragile. They break whenever internal code is refactored, even if the observable behavior remains perfectly correct. High-quality tests assert against the **public contract**, not private mechanics.

- **The Refactoring Litmus Test:** If you rename a private helper method, extract a calculation into an internal class, or change an internal collection from an `ArrayList` to a `HashMap`, your tests **must remain green**. If they fail, they were coupled to implementation details.
- **The Antipattern of Testing Private Methods:** Never make private methods package-private or use reflection (`setAccessible(true)`) just to write unit tests. If a private method contains complex logic that feels urgent to test independently, it violates the Single Responsibility Principle: extract it into a separate collaborator class with its own public contract.
- **Avoid Over-Verification:** Do not assert that internal getters were called, or verify private method invocation sequencing. Assert observable state changes, return values, and essential outbound boundary messages.

```java
package com.example.domain.order;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import static org.assertj.core.api.Assertions.assertThat;

class ContractVsImplementationTest {

    @Test
    @DisplayName("Contract: Order total includes subtotal plus calculated tax regardless of internal algorithm")
    void shouldComputeCorrectTotalAccordingToPublicContract() {
        // Arrange: Testing through the public interface
        Order order = Order.createDraft(OrderId.of("ORD-1"));
        order.addItem(new OrderItem(ProductId.of("P-1"), Quantity.of(1), Money.of(new BigDecimal("100.00"), Currency.USD)));
        TaxCalculator taxCalculator = new StandardTaxCalculator();

        // Act: Invoking the public contract
        Money totalWithTax = order.calculateTotalWithTax(taxCalculator);

        // Assert: Verifying observable contract outcome (100.00 + 10% tax = 110.00)
        // No checks on what private loops were used or whether calculateSubtotal() was called internally
        assertThat(totalWithTax.amount()).isEqualByComparingTo(new BigDecimal("110.00"));
    }
}
```

- [ ] Tests exercise the public API and contracts of the SUT
- [ ] Private methods are never tested directly via reflection
- [ ] Complex private logic is extracted into separate, testable domain classes
- [ ] Tests remain green during pure internal code refactoring
- [ ] Verification targets observable return values and domain state changes

------
