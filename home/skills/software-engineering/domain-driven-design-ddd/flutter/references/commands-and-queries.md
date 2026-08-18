# Commands and Queries Implementation

## Commands. Location: `[context-name]/domain/model/commands/`

Commands represent intentions to change state. They carry all required data for write operations.

- **Naming Convention:** File names end with `.command.dart`; exported names end with `Command`.
- **Use Classes:** Commands are immutable Dart classes.
- **Specific Naming:** Use explicit business intention naming.
- **Validation Ready:** Include all operation inputs.

-  All command files end with `.command.dart`
-  Exported command names end with `Command`
-  Specific and descriptive naming
-  Input validation in creator function
-  Value objects used for complex fields
-  All necessary operation data included

---

## Queries. Location: `[context-name]/domain/model/queries/`

Queries represent requests for information and filtering criteria.

- **Naming Convention:** File names end with `.query.dart`; exported names end with `Query`.
- **Use Classes:** Immutable query models.
- **Specific Naming:** Query names describe exact read intention.
- **Read-Only:** Queries never trigger state modification.
- **Validation:** Validate filters and pagination constraints.

-  All query files end with `.query.dart`
-  Exported query names end with `Query`
-  Specific and descriptive naming
-  Validation for search criteria
-  Optional parameters clearly defined
-  Pagination parameters included when needed
