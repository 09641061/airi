# REST Layer Unit Tests (Controllers, Resources, Transformers, Errors)

## Controllers. Location: `[context-name]/interfaces/rest/`

Controller tests should validate HTTP behavior and request handling. Use `@WebMvcTest` and mock application services.

- **Use Web Layer Slice:** Use `@WebMvcTest` instead of loading the full Spring context
- **Mock Services:** Command and query services must be mocked
- **Status Codes:** Test `200`, `201`, `204`, `400`, `404`, and conflict/error cases where applicable
- **Request Validation:** Test invalid request body and missing fields
- **Path Variables:** Test invalid and valid path variables
- **Query Parameters:** Test filters, pagination, and search parameters
- **No Business Logic:** Controllers should delegate to services
- **No Real Database:** Controller tests must not connect to persistence
- **Security Testing:** Use `Spring Security Test` to mock authenticated users (e.g., `@WithMockUser`) and verify authorization constraints (`401`/`403`)

Checklist:
- [ ] `@WebMvcTest` is used
- [ ] Services are mocked
- [ ] Successful HTTP responses are tested
- [ ] Security rules and mock users are tested
- [ ] Bad request responses are tested
- [ ] Not found responses are tested
- [ ] Conflict/error responses are tested when applicable
- [ ] Request validation is tested
- [ ] Controller delegates to service
- [ ] No database is used

## REST Resources. Location: `[context-name]/interfaces/rest/resources/`

REST resources should be tested when they contain validation rules, computed values, factory methods, or transformation behavior.

- **Validation Annotations:** Test validation through controller tests when possible
- **Resource Construction:** Test only if resource has custom logic
- **Avoid Empty Tests:** Do not test simple records with no behavior
- **Transformation Logic:** If transformation exists inside the resource, test it directly
- **No DTO Over-Testing:** Do not create tests that only check record getters

Checklist:
- [ ] Resource validation is covered
- [ ] Custom resource logic is tested
- [ ] Transformation behavior is tested if present
- [ ] Simple record accessors are not over-tested

## Transformers. Location: `[context-name]/interfaces/rest/transform/`

If transformers exist, they must be tested as pure unit tests because they convert between API input/output and domain commands, queries, or resources.

- **Request to Command:** Test transformation from request/resource to command
- **Request to Query:** Test transformation from request/resource to query
- **Aggregate to Resource:** Test transformation from aggregate/entity to API resource
- **Null Handling:** Test invalid or null input if allowed
- **Naming:** Transformer tests must clearly specify source and target
- **No Repository Access:** Transformers must not use repositories or services

Checklist:
- [ ] Request-to-command transformation is tested
- [ ] Request-to-query transformation is tested
- [ ] Aggregate-to-resource transformation is tested
- [ ] Null or invalid input is tested
- [ ] No repository or service is used
- [ ] Transformation naming is explicit

## Exception and Error Handling

Custom exceptions and error handlers must be tested when they define domain-specific or API-specific behavior.

- **Domain Exceptions:** Test exception creation and message
- **Application Exceptions:** Test business use case exceptions
- **Controller Advice:** Test HTTP response mapping
- **Consistency:** Error responses must follow the expected API format
- **No Silent Failures:** Tests should verify that invalid operations fail explicitly

Checklist:
- [ ] Domain exceptions are tested
- [ ] Application exceptions are tested
- [ ] HTTP exception mapping is tested
- [ ] Error response structure is tested
- [ ] Invalid operations do not fail silently
