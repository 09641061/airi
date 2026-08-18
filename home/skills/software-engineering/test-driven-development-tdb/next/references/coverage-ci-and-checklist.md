# Coverage, CI, Commands, Sequence & Pitfalls

## Coverage Expectations

Coverage should measure confidence in behavior, not only a percentage.

Prioritize:

```text
Domain rules: High coverage
Value objects and aggregates: High coverage
Application services: High coverage
Server Actions and Route Handlers: Medium to high coverage
Components: Meaningful states and interactions
Repositories and adapters: Integration coverage for custom behavior
E2E: Critical user journeys
```

- Business rules, validation, and failure paths must be covered
- Infrastructure glue should not be tested artificially
- Do not chase 100% coverage without meaningful assertions
- Configure the coverage command used by the project, for example `vitest --coverage`

## Continuous Integration Requirements

Tests must run automatically in CI.

- Run unit tests on every push and pull request
- Run integration tests with isolated infrastructure
- Run E2E tests against a built application when configured
- Generate a coverage report
- Fail the pipeline when relevant tests fail
- Do not disable or ignore tests to make the pipeline pass

## Test Execution Commands

```bash
bun run test
bun run test:unit
bun run test:integration
bun run test:e2e
bun run test:coverage
```

For a specific test file:

```bash
bunx vitest run path/to/file.test.ts
bunx playwright test path/to/file.spec.ts
```

## Recommended Testing Sequence

1. **Value Objects** - Test valid, invalid, and boundary values
2. **Commands and Queries** - Test input contracts and validation
3. **Entities and Aggregates** - Test invariants and state transitions
4. **Domain Services** - Test pure business policies
5. **Application Services** - Test use-case flows with mocked dependencies
6. **Repositories and Adapters** - Test custom persistence and integration behavior
7. **Server Actions** - Test validation, delegation, errors, and revalidation
8. **Route Handlers** - Test HTTP contracts and delegation
9. **Components and Server Components** - Test visible behavior and states
10. **E2E Flows** - Test critical journeys in the running application
11. **Coverage and CI** - Verify the suite runs consistently in the pipeline

## Common Pitfalls to Avoid

1. **Do not connect unit tests to a real database or external API.** Use mocks, MSW, or integration infrastructure according to the test level.
2. **Do not mock domain behavior.** Use real value objects and aggregates so business rules remain visible.
3. **Do not test only successful flows.** Include invalid input, edge cases, authorization failures, and dependency errors.
4. **Do not test implementation details.** Assert behavior, outcomes, accessibility, and meaningful interactions.
5. **Do not depend on test execution order.** Each test must create and clean up its own state.
6. **Do not over-test framework internals.** Test the application boundary built on top of Next.js.
7. **Do not use E2E tests for every case.** Keep the broad suite focused on user journeys.
8. **Do not ignore failing tests.** Fix the behavior or correct the test's assumption.

## Final Next.js DDD Testing Checklist

```text
DOMAIN
[ ] Value objects cover valid, invalid, and boundary values
[ ] Commands and queries validate their input
[ ] Entities and aggregates protect invariants
[ ] State transitions and domain events are covered when used
[ ] Domain services cover business rules and edge cases

APPLICATION
[ ] Application services cover successful and failing flows
[ ] Repositories are mocked in unit tests
[ ] Persistence is not called when a use case fails
[ ] Query services do not modify state
[ ] External integrations are isolated

NEXT.JS INTERFACES
[ ] Client Components cover user behavior and accessible states
[ ] Server Components cover successful, empty, and error states
[ ] Server Actions validate input and delegate to use cases
[ ] Route Handlers cover HTTP status codes and response bodies
[ ] Cache revalidation is covered when configured

TEST QUALITY
[ ] Tests follow Arrange, Act, Assert
[ ] Tests use behavior-based names
[ ] Tests are independent and deterministic
[ ] Unit, integration, and E2E responsibilities are separated
[ ] Tests can run from the terminal
[ ] Coverage is generated in CI
```
