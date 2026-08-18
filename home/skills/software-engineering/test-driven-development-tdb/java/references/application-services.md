# Application Service Unit Tests (Command, Query, ACL)

## Command Service Implementations. Location: `[context-name]/application/internal/commandservices/`

Command service implementations orchestrate write use cases. Unit tests must verify business flow, repository interactions, external service usage, and failure paths.

- **Mock Dependencies:** Mock repositories, ACL services, event publishers, and external collaborators
- **Successful Flow:** Test the complete successful command handling path
- **Business Rule Failure:** Test duplicate checks, ownership checks, permission checks, state restrictions, or domain validation failures
- **Repository Save:** Verify that `save` is called only when operation is valid
- **No Save on Failure:** Verify that no persistence happens when a rule fails
- **Exception Handling:** Test meaningful exceptions and messages
- **Transactional Behavior:** Do not test Spring transaction internals in unit tests

Checklist:
- [ ] Dependencies are mocked
- [ ] Successful command handling is tested
- [ ] Business rule failures are tested
- [ ] Repository lookup is verified
- [ ] Repository save is verified
- [ ] Save is not called on failure
- [ ] External ACL behavior is mocked
- [ ] Exception type and message are verified

## Query Service Implementations. Location: `[context-name]/application/internal/queryservices/`

Query service implementations handle read use cases. Unit tests must verify that the correct repository methods are called and the correct results are returned.

- **Mock Repository:** Do not connect to a real database
- **Found Case:** Test when data exists
- **Not Found Case:** Test when data does not exist
- **List Results:** Test empty and non-empty lists
- **Pagination:** Test pageable queries when applicable
- **No State Change:** Verify that `save`, `delete`, or update methods are not called
- **Read-Only Flow:** The service should only retrieve and return data

Checklist:
- [ ] Repository is mocked
- [ ] Found result is tested
- [ ] Not found result is tested
- [ ] Empty list result is tested
- [ ] Non-empty list result is tested
- [ ] Pagination is tested when applicable
- [ ] No state-changing repository method is called

## ACL Services. Location: `[context-name]/application/internal/outboundservices/acl/`

ACL services protect the bounded context from external context models. Unit tests must verify translation, fallback behavior, and error handling.

- **Mock External Facade:** Never call another bounded context directly in unit tests
- **Successful Lookup:** Test when external context returns a valid ID or value
- **Not Found Lookup:** Test when external context returns `0`, `null`, or empty result
- **Creation Flow:** Test external creation when applicable
- **Failure Handling:** Test external failure or invalid response
- **Translation:** Verify that external primitive values are converted into local value objects
- **No Domain Leakage:** Do not expose external domain objects to the local context

Checklist:
- [ ] External facade is mocked
- [ ] Successful external lookup is tested
- [ ] Empty external lookup is tested
- [ ] External creation is tested when needed
- [ ] External failure is tested
- [ ] Translation into local value objects is tested
- [ ] External domain objects are not leaked
