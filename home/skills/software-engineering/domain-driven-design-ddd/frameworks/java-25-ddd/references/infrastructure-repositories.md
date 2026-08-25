# Infrastructure Repositories

Location: `[context-name]/infrastructure/persistence/jpa/repositories/`

Repositories implement aggregate persistence and retrieval.

- **Interface contracts**: Keep domain repository contracts clean
- **Naming Convention**: Files end with `Repository`
- **JPA Integration**: Extend Spring Data interfaces as needed
- **Annotations**: Use `@Repository`
- **Aggregate Focus**: One repository per aggregate root as default rule

## Checklist

- [ ] Repositories are interfaces
- [ ] Extend `JpaRepository` with correct types
- [ ] Use `@Repository`
- [ ] File names end with `Repository`
- [ ] Include derived query methods
- [ ] Add custom `@Query` methods only when required
