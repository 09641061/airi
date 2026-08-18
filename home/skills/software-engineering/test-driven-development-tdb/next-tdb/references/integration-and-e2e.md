# Integration & End-to-End Tests

## Integration Tests

Use integration tests when real components must collaborate.

Examples:

- Repository with a test database
- Route Handler with an application service
- Server Action with a validation schema and use case
- Database queries, mappings, and transactions
- External adapter with an intercepted HTTP response

Integration infrastructure must be isolated, deterministic, and disposable. Test data must not depend on production seed data.

## End-to-End Tests

Use **Playwright** for complete user journeys through the running application.

Test:

- Navigation and protected routes
- Authentication flows
- Form submission
- Server Component rendering
- Loading, empty, and error pages
- Successful and rejected mutations
- Visible results after cache revalidation
- Critical user journeys across bounded contexts

Run E2E tests against a production build when possible:

```bash
bun run build
bunx playwright test
```

Do not use E2E tests for behavior that can be verified faster at the domain, application, or component layer.
