# Application Service & Infrastructure Testing Policy

## Application Services. Location: `contexts/[context]/application/`

Application services orchestrate use cases and coordinate repositories, gateways, and domain objects.

Mock dependencies outside the application service and test:

- Successful command and query flows
- Input validation and business rule failures
- Not-found scenarios
- Dependency and external service errors
- Correct repository and gateway interactions
- The fact that persistence is not called when the operation fails
- Read operations that do not modify state

```ts
expect(repository.save).not.toHaveBeenCalled()
```

Do not test transaction or framework internals in unit tests.

## Repository and Gateway Testing Policy. Location: `contexts/[context]/infrastructure/`

Repositories and gateways should be tested according to the behavior they add.

- Mock repositories and gateways in application service unit tests
- Do not unit test an adapter that only delegates to an unchanged library API
- Test custom mapping, query, serialization, or error-handling logic
- Use integration tests for real database queries, mappings, migrations, and persistence behavior
- Use MSW or equivalent request interception for external HTTP integrations
- Never connect tests to production databases or production APIs
