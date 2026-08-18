# Mocking Rules & Test Data Strategy

## Mocking Rules

Mocks should represent dependencies outside the unit under test.

- Mock repositories, gateways, and external services in application service tests
- Mock Next.js modules only when testing an adapter that uses them
- Use real value objects, commands, queries, entities, and aggregates
- Do not mock the class under test
- Prefer MSW for HTTP behavior instead of mocking `fetch` in every test
- Avoid broad mocks that hide the behavior being verified

## Test Data Strategy

Test data must be explicit, deterministic, and easy to understand.

- Prefer simple valid values
- Use builders or factories for complex aggregates
- Keep scenario-specific data close to the test
- Avoid random values unless the test controls the seed
- Do not depend on production fixtures or shared mutable fixtures
- Name variables according to their role in the scenario
