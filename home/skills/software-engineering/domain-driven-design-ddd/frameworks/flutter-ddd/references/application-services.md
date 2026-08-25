# Application Services (Command/Query Service Implementations)

## Command Service Implementations. Location: `[context-name]/application/internal/commandservices/`

Command service implementations orchestrate write use cases using domain rules and gateways.

- **Naming Convention:** Files end with `CommandServiceImpl`.
- **Injectable Service:** Expose via a `@riverpod` provider (codegen).
- **Interface Implementation:** Implement matching domain command service interface.
- **Error Handling:** Return meaningful domain/application errors; prefer a `Result`/`Either`-style sealed return over throwing across the application boundary when the UI needs to branch on failure kind.

-  Implements domain command service interface
-  File name ends with `CommandServiceImpl`
-  Uses Riverpod codegen for injection
-  Proper business rule validation
-  Error handling with meaningful messages
-  Dependency injection for gateways/ACL services

---

## Query Service Implementations. Location: `[context-name]/application/internal/queryservices/`

Query service implementations handle reads for UI consumption.

- **Naming Convention:** Files end with `QueryServiceImpl`.
- **Injectable Service:** Expose via a `@riverpod` provider (codegen); reads consumed by widgets via `AsyncNotifierProvider`/`FutureProvider` so the UI gets `AsyncValue` loading/error/data states for free.
- **Interface Implementation:** Implement matching domain query service interface.
- **Read-Only:** Never perform write operations.
- **Performance:** Optimize read flows (pagination/filtering/caching as needed); rely on Riverpod's built-in caching/`keepAlive`/`autoDispose` instead of hand-rolled memoization.

-  Implements domain query service interface
-  File name ends with `QueryServiceImpl`
-  Uses Riverpod codegen for injection
-  No state modifications
-  Efficient data retrieval strategy
-  Proper pagination handling
