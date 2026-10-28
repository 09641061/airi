# Application Commands & Queries

## Commands. Location: `[context-name]/application/commands/`

A command expresses an intention to change state (`ConfirmEnrollment`, `CreateCourse`). Prefer specific business intent over a generic CRUD patch.

- **Records** when they fit well.
- **Specific naming:** `ConfirmEnrollmentCommand`, not `UpdateCommand`.
- **Validation:** the handler maps input values to domain value objects; the aggregate — not the DTO — enforces the invariants.

```java
// File: [context-name]/application/commands/ConfirmEnrollmentCommand.java
package com.acme.center.platform.[context].application.commands;

public record ConfirmEnrollmentCommand(Long enrollmentId) {
    public ConfirmEnrollmentCommand {
        if (enrollmentId == null || enrollmentId <= 0) {
            throw new IllegalArgumentException("Enrollment id must be positive");
        }
    }
}
```

### Checklist (commands)

- [ ] All commands are records
- [ ] File names end with `Command`
- [ ] Named after business intent
- [ ] No business logic inside the command
- [ ] Located in `application/commands`, not in `domain/model/commands`

## Queries. Location: `[context-name]/application/queries/`

A query requests information and must not mutate state. Its result can be an application read model; it does not need to be a domain aggregate.

```java
// File: [context-name]/application/queries/CourseSummaryQuery.java
package com.acme.center.platform.[context].application.queries;

public record CourseSummaryQuery(Long courseId) {
    public CourseSummaryQuery {
        if (courseId == null || courseId <= 0) {
            throw new IllegalArgumentException("Course id must be positive");
        }
    }
}
```

### Checklist (queries)

- [ ] All queries are records
- [ ] File names end with `Query`
- [ ] Named after query intent
- [ ] `Optional` for optional parameters
- [ ] Pagination/sorting only when the use case or the API requires them
- [ ] An established HTTP contract is never altered as a side effect of a refactor
