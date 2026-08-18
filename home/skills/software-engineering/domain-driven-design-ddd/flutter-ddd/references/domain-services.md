# Domain Services

Location: `[context-name]/domain/services/`

Domain services define contracts for commands and queries.

- **Abstract Only:** Domain services are abstract Dart classes.
- **Naming Convention:** Files end with `.command-service.dart` or `.query-service.dart`.
- **CQRS Separation:** Command and query contracts are separate.
- **Business Focus:** Methods represent business use cases.

-  All services are abstract contracts
-  Separate Command and Query services
-  File names end with correct suffix
-  `handle()`/use-case methods exist for each command/query
-  Return appropriate async types (`Future`/`Stream`)
-  Clear business-focused method names
