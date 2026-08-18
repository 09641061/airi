# Application Services (Command & Query implementations)

## Command Service Implementations

Location: `[context-name]/application/internal/commandservices/`

Command implementations orchestrate business operations.

- **Naming Convention**: `*CommandServiceImpl` (or `*CommandHandler` if your context uses handler style)
- **Service Annotation**: Use `@Service`
- **Interface Implementation**: Implement domain contracts
- **Transaction Management**: Use `@Transactional`
- **Error Handling**: Domain-meaningful exceptions

Checklist:
- [ ] Implements corresponding domain contract
- [ ] Uses `@Service`
- [ ] Uses `@Transactional` appropriately
- [ ] Business rule validation included
- [ ] Meaningful exception handling
- [ ] Repository dependency injection via constructor

## Query Service Implementations

Location: `[context-name]/application/internal/queryservices/`

Query implementations handle read operations only.

- **Naming Convention**: `*QueryServiceImpl` (or `*QueryHandler`)
- **Service Annotation**: Use `@Service`
- **Read-Only**: Use `@Transactional(readOnly = true)`
- **Performance**: Optimize read paths and pagination

Checklist:
- [ ] Implements corresponding domain query contract
- [ ] Uses `@Service`
- [ ] `@Transactional(readOnly = true)` used
- [ ] No state modifications
- [ ] Efficient data retrieval
- [ ] Proper pagination/sorting
