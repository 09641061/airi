# Assertions, Exceptions & Failure Contracts

This reference covers assertion selection, diagnostics, exception contracts, and appropriate use of `assertDoesNotThrow`.

### 6. Assertion Paradigms: JUnit Jupiter vs. AssertJ. Scope: Expressiveness & Diagnostics

Selecting the appropriate assertion mechanism directly impacts test maintainability and diagnostic clarity during failures. JUnit Jupiter provides standard assertions (`org.junit.jupiter.api.Assertions`), while AssertJ (`org.assertj.core.api.Assertions`) delivers a rich, fluent assertion library.

#### Engineering Heuristic: Choosing Between JUnit and AssertJ
- **Use JUnit Jupiter Assertions (`assertEquals`, `assertTrue`, `assertNull`)** for simple scalar checks, boolean flags, or minimal tests where external dependencies are avoided.
- **Prefer AssertJ (`assertThat`)** for complex objects, collections, deep graph comparisons, custom domain assertions, and scenarios where failure message diagnostics must immediately expose discrepancies without debugging.

#### AssertJ 3.26+ Capabilities
1. **Recursive Comparison:** `usingRecursiveComparison()` compares complex object graphs field-by-field without requiring `.equals()` implementations on every nested DTO or entity, while allowing specific ignored fields (such as generated timestamps or IDs).
2. **Collection Fluent Assertions:** `extracting()`, `containsExactly()`, `containsExactlyInAnyOrder()`, `filteredOn()`, and `allSatisfy()` allow precise verification of element states in collections.
3. **Soft Assertions (`assertSoftly`):** Similar to JUnit's `assertAll()`, AssertJ's `assertSoftly()` collects all assertion failures within a block and reports them together rather than stopping at the first failure.
4. **Failure Diagnostics:** When an assertion fails, AssertJ formats diffs clearly, highlighting exact mismatched fields, missing collection elements, or unexpected values.

```java
package com.example.domain.order;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.SoftAssertions.assertSoftly;
import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;

class OrderAssertionComparisonTest {

    @Test
    void shouldVerifyStateUsingAssertJFluentStyle() {
        // Arrange
        OrderId orderId = OrderId.of("ORD-999");
        CustomerId customerId = CustomerId.of("CUST-123");
        Money total = Money.of(new BigDecimal("250.00"), Currency.USD);
        Order order = new Order(orderId, customerId, total, OrderStatus.PENDING);
        order.addItem(new OrderItem(ProductId.of("P-1"), Quantity.of(2), Money.of(new BigDecimal("100.00"), Currency.USD)));
        order.addItem(new OrderItem(ProductId.of("P-2"), Quantity.of(1), Money.of(new BigDecimal("50.00"), Currency.USD)));

        // AssertJ: Fluent, expressive, and detailed failure diagnostics
        assertThat(order.getItems())
            .hasSize(2)
            .extracting(OrderItem::getProductId)
            .containsExactly(ProductId.of("P-1"), ProductId.of("P-2"));

        assertThat(order)
            .satisfies(o -> {
                assertThat(o.getId()).isEqualTo(orderId);
                assertThat(o.getStatus()).isEqualTo(OrderStatus.PENDING);
                assertThat(o.getTotalAmount()).isEqualTo(total);
            });
    }

    @Test
    void shouldCompareComplexGraphsUsingRecursiveComparison() {
        // Arrange
        Order expected = new Order(OrderId.of("ORD-1"), CustomerId.of("C-1"), Money.of(new BigDecimal("100.00"), Currency.USD), OrderStatus.PENDING);
        Order actual = new Order(OrderId.of("ORD-1"), CustomerId.of("C-1"), Money.of(new BigDecimal("100.00"), Currency.USD), OrderStatus.PENDING);
        actual.setCreatedAt(Instant.now()); // Has dynamic timestamp

        // Act & Assert: Ignoring transient or timestamp fields during graph comparison
        assertThat(actual)
            .usingRecursiveComparison()
            .ignoringFields("createdAt")
            .isEqualTo(expected);
    }

    @Test
    void shouldCompareGroupedAssertionsInBothLibraries() {
        Order order = new Order(OrderId.of("ORD-1"), CustomerId.of("C-1"), Money.of(BigDecimal.TEN, Currency.USD), OrderStatus.PENDING);

        // JUnit Jupiter grouped assertions:
        assertAll("Order attributes via JUnit",
            () -> assertEquals(OrderId.of("ORD-1"), order.getId()),
            () -> assertEquals(OrderStatus.PENDING, order.getStatus())
        );

        // AssertJ Soft Assertions:
        assertSoftly(softly -> {
            softly.assertThat(order.getId()).isEqualTo(OrderId.of("ORD-1"));
            softly.assertThat(order.getStatus()).isEqualTo(OrderStatus.PENDING);
        });
    }
}
```

- [ ] AssertJ is preferred for collections, object graphs, and multi-property verifications
- [ ] Simple scalar assertions use either JUnit `assertEquals` or AssertJ `assertThat`
- [ ] Object graphs are verified with `usingRecursiveComparison()` when appropriate
- [ ] Grouped assertions (`assertAll` or `assertSoftly`) prevent fail-fast masking of related fields
- [ ] Expected values precede actual values in JUnit assertions: `assertEquals(expected, actual)`

------


### 7. Exception Testing: Contracts & Polymorphism. Scope: `assertThrows` vs. `assertThrowsExactly` & `assertDoesNotThrow`

A domain model specifies failure paths as strictly as success paths. Invariants throw domain exceptions when violated. Selecting the right assertion depends on the exception contract:

#### Heuristic: `assertThrows` vs. `assertThrowsExactly`
- **Use `assertThrows(ExpectedException.class, ...)` by default:** In object-oriented design, exceptions often form polymorphic hierarchies. If an interface or domain service declares throwing a `PaymentException`, the contract is satisfied whether the concrete instance thrown is `CardDeclinedException` or `InsufficientFundsException`. Demanding the exact concrete type when the general contract suffices causes brittle tests.
- **Use `assertThrowsExactly(ConcreteException.class, ...)` selectively:** When distinguishing between different subclasses that represent distinct error handling semantics (e.g., verifying that a method throws `DuplicateEmailException` rather than its superclass `ValidationException`, or distinguishing `IllegalArgumentException` from `NumberFormatException`).

#### Pragmatic Assessment of `assertDoesNotThrow`
Asserting that an operation "does not throw" is weak verification for state-changing operations. For example:
```java
// WEAK: Proves only that the code did not crash; gives no guarantee that state changed
assertDoesNotThrow(() -> order.addItem(item));
```
If an operation modifies state, verify that the state actually changed (`assertThat(order.getItems()).contains(item)`).
- **Legitimate use case for `assertDoesNotThrow`:** Idempotent, void operations whose sole observable contract is successful execution without throwing an exception (e.g., closing a resource cleanly, executing a cache eviction on a missing key, or running an idempotent cleanup routine).

```java
package com.example.domain.order;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

class OrderExceptionContractTest {

    @Test
    void shouldThrowPolymorphicDomainExceptionWhenPaymentFails() {
        PaymentProcessor processor = new FailingPaymentProcessor();

        // Contract verification: Accepts any PaymentException subclass
        PaymentException exception = assertThrows(
            PaymentException.class,
            () -> processor.charge(OrderId.of("ORD-1"), Money.of(BigDecimal.TEN, Currency.USD)),
            "Should throw PaymentException contract on processing failure"
        );

        assertThat(exception.getMessage()).contains("Payment gateway timeout");
    }

    @Test
    void shouldThrowExactExceptionWhenQuantityIsNegative() {
        // Invariant verification: Must specifically be InvalidQuantityException, not generic RuntimeException
        InvalidQuantityException exception = assertThrowsExactly(
            InvalidQuantityException.class,
            () -> Quantity.of(-5),
            "Negative quantity must throw exact InvalidQuantityException"
        );

        assertThat(exception.getErrorCode()).isEqualTo("ERR_NEGATIVE_QUANTITY");
    }

    @Test
    void shouldNotThrowWhenEvictingNonExistentCacheKey() {
        OrderCache cache = new InMemoryOrderCache();

        // Legitimate use: Idempotent void method with no return value or state change
        assertDoesNotThrow(
            () -> cache.evict("NON_EXISTENT_KEY"),
            "Evicting an absent key from cache should execute cleanly without error"
        );
    }
}
```

- [ ] `assertThrows` is used by default for polymorphic exception contract verification
- [ ] `assertThrowsExactly` is reserved for scenarios where exact concrete exception types are mandatory
- [ ] Thrown exception instances are inspected for error codes, messages, or nested causes
- [ ] `assertDoesNotThrow` is avoided for state-changing methods; state changes are explicitly verified
- [ ] `assertDoesNotThrow` is used for idempotent void operations with no other observable outcome

------
