# Domain Services

## 5. Domain Services

**Location:** `[context-name]/domain/services/`

Use a Domain Service for **domain logic that does not naturally belong to an entity or Value Object**.

- **Business focus:** express domain rules, not HTTP or database operations.
- **Interfaces:** define a small interface when a domain contract really needs one. No interface is mandatory for every struct.
- **Naming:** prefer `[BusinessCapability]Service`; use `CommandService` and `QueryService` for application orchestration when appropriate.
- **Return values:** use typed values and `error` rather than Java `Optional` or exceptions.

- [ ] Domain services contain business behavior only.
- [ ] Interfaces are small and justified.
- [ ] Commands and queries separated where useful.
- [ ] Methods use clear business names.
- [ ] No Gin/SQL/configuration dependencies.

---
