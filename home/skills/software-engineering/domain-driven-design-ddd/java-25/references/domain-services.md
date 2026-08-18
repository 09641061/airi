# Domain Services

Location: `[context-name]/domain/services/`

Domain services define business capabilities that do not belong naturally to an entity/value object.

- **Interface first**: Domain contracts as interfaces
- **Naming Convention**: `*CommandService` or `*QueryService` or explicit use-case names
- **Separation**: Keep command and query responsibilities separated (CQRS)
- **Business Focus**: No infrastructure concerns in domain

## Checklist

- [ ] Services defined as domain contracts
- [ ] Command and query responsibilities separated
- [ ] Clear business-focused method names
- [ ] Return appropriate types (`Optional`, collections, typed results)
