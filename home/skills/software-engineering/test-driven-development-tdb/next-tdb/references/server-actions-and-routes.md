# Server Actions & Route Handler Tests

## Server Actions

Server Actions should be tested as adapters between form input, validation, and application services.

Test:

- Input parsing and schema validation
- Command creation
- Application service invocation
- Successful return values
- Domain and application errors
- Authorization failures
- Cache revalidation when configured

Mock only the dependencies required by the test, such as:

- `next/server` for request/response shapes
- `next/cache` for cache APIs like `revalidateTag`
- `next/headers` for `cookies()` (async since Next 15), `headers()`, `draftMode()`
- any third-party HTTP client your action routes through

Do not confuse `cookies()` from `next/headers` (which is async since Next 15) with `NextRequest#cookies`.

Do not test Next.js framework implementation details.

## Route Handlers. Location: `app/**/route.ts`

Route Handler tests should validate HTTP behavior and delegation to application services.

Test:

- Request parsing and path parameters
- Query parameters and headers
- Valid and invalid request bodies
- Response status and body
- Authentication and authorization failures
- Not-found, conflict, and unexpected error responses
- Delegation to the correct application service

Use mocked services for unit tests and a real application boundary for integration tests. Do not connect unit tests to a real database.
