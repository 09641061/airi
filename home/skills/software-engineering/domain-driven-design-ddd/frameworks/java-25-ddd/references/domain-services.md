# Domain Services

Location: `[context-name]/domain/services/`

Domain services hold **pure business logic** that does not naturally belong to a single entity or value object — typically a policy or calculation that spans several aggregates. They do **not** orchestrate use cases.

- **Interface first**: domain contracts as Java interfaces, **without Spring/JPA imports**.
- **Naming Convention**: `*Policy`, `*Calculator`, `*Specification`, or any name from the ubiquitous language. Do **not** use `*CommandService` or `*QueryService` here — those are application-layer concepts and live in `application/internal/`.
- **No infrastructure**: no `@Service`, no `@Transactional`, no repository dependencies. If a service needs a repository, it is an application service, not a domain service.
- **Stateless**: holds no state between invocations.
- **Business focus**: only domain rules; nothing about HTTP, transactions, or persistence.

## What a domain service is NOT

- It is not an application service (those orchestrate use cases; see `application-services.md`).
- It is not a repository (those persist aggregates; see `infrastructure-repositories.md`).
- It is not a domain event handler (those consume events asynchronously).

## Checklist

- [ ] Interface defined in `domain/services/`
- [ ] No `org.springframework.*` or `jakarta.persistence.*` imports
- [ ] No `*CommandService` / `*QueryService` naming — those belong to the application layer
- [ ] Methods express business rules in the ubiquitous language
- [ ] Method returns are domain types or built-in Java types (no DTOs)
- [ ] Stateless
