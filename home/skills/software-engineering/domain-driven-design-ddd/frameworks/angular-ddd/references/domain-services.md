# Domain Services

Location: `[context-name]/domain/services/`

Domain services define contracts for commands and queries.

- **Interface Only:** Domain services are TypeScript interfaces.
- **Naming Convention:** Files end with `.command-service.ts` or `.query-service.ts`.
- **CQRS Separation:** Command and query contracts are separate.
- **Business Focus:** Methods represent business use cases.

- [ ] All services are interfaces/contracts
- [ ] Separate Command and Query services
- [ ] File names end with correct suffix
- [ ] `handle`/use-case methods exist for each command/query
- [ ] Return appropriate async types (`Observable`/`Promise`)
- [ ] Clear business-focused method names
