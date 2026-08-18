# Value Objects Implementation

Location: `[context-name]/domain/model/valueobjects/`

Value objects represent validated domain concepts used across commands, queries, entities, and UI logic.

- **Use TypeScript Types:** Implement value objects with `type`/`interface` plus factory functions.
- **Validation:** Include business validation inside creator function.
- **Immutable:** Return immutable shapes (`Readonly<T>` or frozen objects).
- **Domain Safety:** Replace primitives with value objects when fields are business-critical.

- [ ] Value objects use `type`/`interface`
- [ ] Validation logic exists in creator function
- [ ] Null checks and business rule validation implemented
- [ ] Enums/union types used for predefined values
- [ ] Immutable by design

IMPORTANT: FOR AGGREGATE ROOT VIEW MODELS, REUSE THE SHARED FRONTEND CORE FOLDER WHEN IT ALREADY DEFINES COMMON ID/AUDIT FIELDS.
