# Coverage, CI, Commands, Timeline & Pitfalls

## Coverage Expectations

Coverage should measure confidence, not only percentage. Prioritize domain and application behavior.

Recommended minimum coverage by layer:

```text
Domain Model: High coverage
Value Objects: High coverage
Aggregates: High coverage
Commands/Queries: Medium to high coverage
Application Services: High coverage
ACL Services: High coverage
Controllers: Medium coverage
Repositories: Covered by integration tests, not unit tests
```

- **Critical Business Rules:** Must be covered
- **Validation Rules:** Must be covered
- **Failure Paths:** Must be covered
- **Infrastructure Glue:** Lower priority for unit tests
- **Do Not Chase 100% Blindly:** Meaningful coverage is more important than artificial coverage

Checklist:
- [ ] Business rules are covered
- [ ] Validation rules are covered
- [ ] Failure paths are covered
- [ ] Application flows are covered
- [ ] Infrastructure is not artificially unit tested
- [ ] JaCoCo report is generated

## Continuous Integration Requirements

Unit tests must run automatically in the CI pipeline.

- **Run on Every Push:** Unit tests must execute on every branch push
- **Run on Pull Request:** Unit tests must block merge if failing
- **Fast Feedback:** Unit tests should finish quickly
- **Fail Fast:** Broken tests should stop the pipeline
- **Coverage Report:** JaCoCo or equivalent report should be generated
- **No Ignored Tests:** Avoid disabling tests to pass the pipeline

Checklist:
- [ ] Unit tests run on every push
- [ ] Unit tests run on every pull request
- [ ] Failing tests block merge
- [ ] Coverage report is generated
- [ ] Tests finish quickly
- [ ] No relevant tests are ignored

## Unit Test Execution Commands

```bash
mvn test
mvn clean test
mvn clean verify
```

For a specific test class:

```bash
mvn -Dtest=SubscriptionCommandServiceImplTest test
```

For a specific test method:

```bash
mvn -Dtest=SubscriptionCommandServiceImplTest#shouldCreateSubscriptionWhenCommandIsValid test
```

## Unit Testing Timeline

1. **Value Object Tests** - Start with basic value objects and ID validation
2. **Enum Tests** - Test enums only when they contain behavior
3. **Command Tests** - Test command creation and validation
4. **Query Tests** - Test query creation and validation
5. **Aggregate Tests** - Test business rules and state transitions
6. **Domain Service Tests** - Test pure domain policies or calculations
7. **Application Command Service Tests** - Test write use cases with mocked repositories
8. **Application Query Service Tests** - Test read use cases with mocked repositories
9. **ACL Service Tests** - Test external context translation and fallback behavior
10. **Transformer Tests** - Test request/response transformations if transformers exist
11. **Controller Tests** - Test HTTP behavior using web-layer tests
12. **Error Handler Tests** - Test API exception mapping if global handlers exist
13. **Coverage Review** - Verify business-critical paths are covered
14. **CI Execution** - Ensure tests run automatically in the pipeline

## Common Pitfalls to Avoid

1. **Do not connect to a real database in unit tests** — use mocks for repositories; use integration tests for persistence.
2. **Do not load the full Spring context unnecessarily** — use plain JUnit and Mockito for most unit tests.
3. **Do not mock value objects or aggregates** — use real domain objects to preserve domain behavior.
4. **Do not test only happy paths** — always test invalid data, edge cases, and failure scenarios.
5. **Do not test implementation details** — test behavior, outcomes, exceptions, and meaningful interactions.
6. **Do not depend on test execution order** — each test must be independent.
7. **Do not ignore failing tests** — fix the behavior or fix the test.
8. **Do not over-test simple getters and setters** — focus on rules, decisions, validations, and state changes.
9. **Do not call external bounded contexts directly** — mock ACL facades and test translation logic.
10. **Do not mix unit and integration testing responsibilities** — unit tests isolate a class or behavior; integration tests validate real collaboration between components.

## Final Bounded Context Unit Testing Checklist

```text
DOMAIN
[ ] Value objects have valid and invalid creation tests
[ ] Commands validate required data
[ ] Queries validate search criteria
[ ] Aggregates protect invariants
[ ] Aggregates test valid and invalid state transitions
[ ] Domain events are tested when used
[ ] Domain services are tested when they contain business logic

APPLICATION
[ ] Command services test successful write flows
[ ] Command services test business rule failures
[ ] Command services verify save is not called on failure
[ ] Query services test found and not found results
[ ] Query services do not modify state
[ ] ACL services test external lookup, empty response, and failure cases

INTERFACES
[ ] Controllers test expected HTTP status codes
[ ] Controllers test security rules if configured
[ ] Controllers test invalid requests
[ ] Controllers delegate to application services
[ ] Transformers are tested if they exist
[ ] Error handlers are tested if they define API responses

TEST QUALITY
[ ] Tests follow Arrange, Act, Assert
[ ] Tests use behavior-based names
[ ] Tests are independent
[ ] Tests are deterministic
[ ] Tests are fast
[ ] Tests do not use real infrastructure
[ ] Tests can run with Maven
[ ] Coverage report is generated
```

## Recommended Minimal Test Set per Bounded Context

```text
1. All value objects with validation
2. All commands with validation
3. All queries with validation
4. All aggregates with business rules
5. All command service implementations
6. All query service implementations
7. All ACL outbound services
8. All REST controllers with main HTTP responses
9. All custom exception handlers
```

This ensures the bounded context is protected from invalid input, broken business rules, incorrect orchestration, and unstable API behavior.
