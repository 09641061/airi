# Test Doubles & Fixture Management

This reference covers the Meszaros test-double taxonomy, pragmatic Mockito usage, Object Mothers, and Test Data Builders.

### 14. Test Doubles Taxonomy & Pragmatic Mocking. Scope: Mocks, Stubs, Fakes & Over-Mocking

In unit testing, isolating the SUT requires substituting external dependencies. According to Gerard Meszaros' classic taxonomy, test doubles serve distinct purposes:

#### The Test Double Taxonomy
1. **Dummy:** Passed to satisfy method signatures (e.g., non-null constructor parameter), but never accessed or invoked during the test.
2. **Stub:** Provides predefined, canned responses to method invocations during test execution. Does not assert interactions.
3. **Spy:** Wraps a real object to record method calls and arguments while delegating behavior to the underlying real object.
4. **Mock:** Pre-programmed with expectations of invocations and parameters. Fails verification if expected calls do not occur.
5. **Fake:** A working, functional in-memory implementation that uses shortcuts unsuitable for production (e.g., an in-memory repository backed by a `ConcurrentHashMap`).

#### Pragmatic Engineering Heuristics for Test Doubles
- **Do Not Default Blindly to Mockito:** In-memory **Fakes** and **Stubs** are frequently superior to Mockito mocks: they execute faster, produce less brittle tests, survive internal refactorings, and verify state rather than implementation interactions.
- **Collaborator Boundaries, Not Just "I/O":** Mocks and stubs are appropriate for isolating collaborator boundaries where real implementations introduce non-determinism, external services, or complex side effects (e.g., third-party payment gateways, asynchronous email senders, or cross-bounded-context client facades).
- **Keep Domain Models Real:** Entities, Value Objects, and Aggregates should be real instances. Mocking a domain entity bypasses its invariants, creating tests that pass while production code fails.
- **Legitimate Use Cases for `@Spy`:** While partial mocking of clean code indicates design flaws, `@Spy` is a pragmatic, valuable tool when refactoring **legacy code** where full dependency injection cannot yet be safely retrofitted, allowing isolation of an untestable legacy seam without breaking the existing class hierarchy.
- **Pragmatic Interaction Verification (`verifyNoMoreInteractions`):**
  - **The Brittleness Hazard:** Systematically placing `verifyNoMoreInteractions()` on all mocks creates brittle tests that break upon adding harmless interactions (e.g., telemetry logging, metrics tracking, or caching lookups).
  - **The Senior Rule:** Verify interactions (`verify()`, `verifyNoMoreInteractions()`) **only when the outbound interaction itself constitutes the business contract** (e.g., charging a credit card, dispatching an external money transfer, or recording an immutable security audit event). For query collaborators, verify the SUT's returned outcome or aggregate state instead of the mock invocation.

```java
package com.example.application.order;

import com.example.domain.order.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SubmitOrderUseCaseTest {

    @Mock
    private OrderRepository orderRepository; // Collaborator stub

    @Mock
    private PaymentGateway paymentGateway;   // External outbound contract mock

    @InjectMocks
    private SubmitOrderUseCase submitOrderUseCase; // SUT

    @Test
    void shouldSubmitOrderSuccessfullyWhenPaymentSucceeds() {
        // Arrange
        OrderId orderId = OrderId.of("ORD-100");
        Order order = Order.createDraft(orderId);
        order.addItem(new OrderItem(ProductId.of("P-1"), Quantity.of(1), Money.of(new BigDecimal("100.00"), Currency.USD)));

        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));
        when(paymentGateway.processPayment(any(PaymentRequest.class))).thenReturn(PaymentResult.success("TXN-999"));

        // Act
        OrderSubmissionResult result = submitOrderUseCase.execute(new SubmitOrderCommand(orderId));

        // Assert: State verification first
        assertThat(result.isSuccess()).isTrue();
        assertThat(order.getStatus()).isEqualTo(OrderStatus.SUBMITTED);

        // Interaction verification: Only on boundary calls that represent business contracts
        verify(orderRepository).save(order);
        verify(paymentGateway).processPayment(any(PaymentRequest.class));
        
        // Explicitly reserved for strict external financial transactions:
        verifyNoMoreInteractions(paymentGateway);
    }
}
```

- [ ] Test doubles are chosen according to Meszaros' taxonomy (Dummy, Stub, Fake, Spy, Mock)
- [ ] In-memory Fakes or Stubs are evaluated before defaulting to Mockito
- [ ] Domain models (Value Objects, Entities) are instantiated as real objects
- [ ] `@Spy` is reserved for refactoring legacy code seams or specific framework integration
- [ ] `verifyNoMoreInteractions` is reserved strictly for side-effect contracts (payments, emails, audits)
- [ ] State verification is prioritized over interaction verification for query collaborators

------


### 18. Test Data Management: Object Mother & Test Data Builder. Scope: Fixture Hygiene

Incoherent test data generation results in brittle tests. Adhering to structured creational patterns preserves readability and domain invariants.

- **Object Mother vs. Test Data Builder:**
  - **Object Mother:** Factory class providing pre-configured named domain objects (e.g., `OrderMother.createStandardOrder()`, `OrderMother.createOverdueOrder()`). Ideal for quick, common scenarios.
  - **Test Data Builder:** Fluent builder initializing valid domain defaults while exposing override methods only for fields relevant to the specific test scenario. Ideal for complex aggregates with multiple variations.
- **Deterministic Fixtures:** Avoid random data generation (`UUID.randomUUID()` or `Math.random()`) in assertions. Keep test fixtures predictable, readable, and reproducible across runs.

```java
package com.example.test.fixtures;

import com.example.domain.order.*;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class OrderTestBuilder {

    private OrderId orderId = OrderId.of("ORD-001");
    private CustomerId customerId = CustomerId.of("CUST-999");
    private OrderStatus status = OrderStatus.PENDING;
    private final List<OrderItem> items = new ArrayList<>();

    public static OrderTestBuilder anOrder() {
        return new OrderTestBuilder();
    }

    public OrderTestBuilder withId(String id) {
        this.orderId = OrderId.of(id);
        return this;
    }

    public OrderTestBuilder withStatus(OrderStatus status) {
        this.status = status;
        return this;
    }

    public OrderTestBuilder withItem(BigDecimal price, int quantity) {
        this.items.add(new OrderItem(ProductId.of("PROD-TEST"), Quantity.of(quantity), Money.of(price, Currency.USD)));
        return this;
    }

    public Order build() {
        Order order = new Order(orderId, customerId, status);
        items.forEach(order::addItem);
        return order;
    }
}
```

```java
package com.example.domain.order;

import com.example.test.fixtures.OrderTestBuilder;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import static org.assertj.core.api.Assertions.assertThat;

class OrderBuilderUsageTest {

    @Test
    void shouldCalculateTotalUsingTestDataBuilder() {
        // Arrange: Explicit fixture setup where only relevant fields are customized
        Order order = OrderTestBuilder.anOrder()
            .withItem(new BigDecimal("20.00"), 2)
            .withItem(new BigDecimal("10.00"), 1)
            .build();

        // Act & Assert
        assertThat(order.calculateSubtotal().amount()).isEqualByComparingTo("50.00");
    }
}
```

- [ ] Test data is centralized using Test Data Builders or Object Mother factories
- [ ] Builders populate valid default values for all required domain fields
- [ ] Tests override only the specific attributes relevant to the scenario being verified
- [ ] Assertions rely on deterministic, reproducible test data
- [ ] Domain objects retain valid invariants when constructed by builders

------
