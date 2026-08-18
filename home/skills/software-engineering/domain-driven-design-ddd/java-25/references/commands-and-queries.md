# Commands & Queries

## Commands

Location: `[context-name]/domain/model/commands/`

Commands represent intentions to change state and are immutable.

- **Naming Convention**: Files end with `Command`
- **Use Records**: Commands should be records
- **Specific Naming**: Name by business intent
- **Validation Ready**: Include all required data

Checklist:
- [ ] All commands are records
- [ ] File names end with `Command`
- [ ] Specific and descriptive naming
- [ ] Input validation in constructor
- [ ] Use value objects for complex types
- [ ] Include all required operation data

## Queries

Location: `[context-name]/domain/model/queries/`

Queries request information and must not mutate state.

- **Naming Convention**: Files end with `Query`
- **Use Records**: Queries should be records
- **Specific Naming**: Name by query intent
- **Validation**: Validate query constraints

Checklist:
- [ ] All queries are records
- [ ] File names end with `Query`
- [ ] Specific and descriptive naming
- [ ] Validation for search criteria
- [ ] Use `Optional` for optional parameters
- [ ] Include pagination/sorting parameters when needed
