# Application Services (Command & Query implementations)

## Layer reminder

Application services orchestrate use cases. They depend on the domain (to load aggregates, invoke business methods, save) and on infrastructure (to open transactions, publish events, send notifications). They are **not** part of the domain and must not be placed in `domain/services/`.

The contract interface for an application service (the public API the interfaces layer calls) lives in `application/internal/` together with its implementation. Domain services (`*Policy`, `*Calculator`) live in `domain/services/` and contain no orchestration — see [domain-services.md](domain-services.md) for that distinction.

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
