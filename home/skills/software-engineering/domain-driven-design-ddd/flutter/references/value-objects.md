# Value Objects Implementation

Location: `[context-name]/domain/model/valueobjects/`

Value objects represent validated domain concepts used across commands, queries, entities, and UI logic.

- **Use Dart Classes:** Implement value objects using immutable Dart classes (`Freezed`-generated where possible) with factory constructors.
- **Validation:** Include business validation inside factory constructors; throw a domain exception, never assert-only.
- **Immutable:** Return immutable objects (`final`, `const`, `Freezed`, immutable classes).
- **Domain Safety:** Replace primitives with value objects when fields are business-critical.
- **Unions:** For a value object with a closed set of variants, prefer a Dart 3 **sealed class** hierarchy over an enum-plus-payload pair, so callers get exhaustiveness checking.

-  Value objects use immutable classes
-  Validation logic exists in factory constructor
-  Null checks and business rule validation implemented
-  Enums or sealed classes used for predefined values/variants
-  Immutable by design

IMPORTANT: FOR AGGREGATE ROOT VIEW MODELS, REUSE THE SHARED FRONTEND CORE FOLDER WHEN IT ALREADY DEFINES COMMON ID/AUDIT FIELDS.
