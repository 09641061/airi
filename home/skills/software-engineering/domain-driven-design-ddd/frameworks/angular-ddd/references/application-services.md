# Application Services (Command/Query Service Implementations)

## Command Service Implementations. Location: `[context-name]/application/internal/commandservices/`

Command service implementations orchestrate write use cases using domain rules and gateways.

- **Naming Convention:** Files end with `CommandServiceImpl`.
- **Injectable Service:** Use Angular `@Injectable`.
- **Interface Implementation:** Implement matching domain command service interface.
- **Error Handling:** Return meaningful domain/application errors.

- [ ] Implements domain command service interface
- [ ] File name ends with `CommandServiceImpl`
- [ ] Uses `@Injectable`
- [ ] Proper business rule validation
- [ ] Error handling with meaningful messages
- [ ] Dependency injection for gateways/ACL services

---

## Query Service Implementations. Location: `[context-name]/application/internal/queryservices/`

Query service implementations handle reads for UI consumption.

- **Naming Convention:** Files end with `QueryServiceImpl`.
- **Injectable Service:** Use Angular `@Injectable` with `inject()` for dependencies.
- **Interface Implementation:** Implement matching domain query service interface.
- **Read-Only:** Never perform write operations.
- **Performance:** Optimize read flows (pagination/filtering/caching as needed).
- **Signal-Friendly:** When consumers are components, prefer exposing state as a `Signal` (via `resource()`/`toSignal()`) so templates can read it directly without `async` pipe boilerplate.

- [ ] Implements domain query service interface
- [ ] File name ends with `QueryServiceImpl`
- [ ] Uses `@Injectable` with `inject()`
- [ ] No state modifications
- [ ] Efficient data retrieval strategy
- [ ] Proper pagination handling
