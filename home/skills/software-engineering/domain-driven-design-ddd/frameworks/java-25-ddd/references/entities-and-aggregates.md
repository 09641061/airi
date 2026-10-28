# Entities and Aggregates

Location: `[context-name]/domain/model/aggregates/`

The aggregate is the transactional boundary: it exposes invariants and intention-revealing methods, and it never allows an invalid state.

- **No public setters:** state changes through business-named methods (`confirm()`, `reject()`, `publish()`).
- **Identity:** identifiers are value objects (`EntityId`), never loose `Long` values in signatures.
- **References by identity:** another aggregate is referenced by its id, not by direct object reference.
- **Domain events:** the aggregate records facts, not framework dependencies.
- **Auditing:** if the platform offers an auditable base model, use it from `shared/`; do not force it when it couples the domain to Spring Data.

```java
// File: [context-name]/domain/model/aggregates/Enrollment.java
package com.acme.center.platform.[context].domain.model.aggregates;

import com.acme.center.platform.[context].domain.model.events.EnrollmentConfirmedEvent;
import com.acme.center.platform.[context].domain.model.valueobjects.EnrollmentId;
import com.acme.center.platform.[context].domain.model.valueobjects.StudentId;

import java.util.ArrayList;
import java.util.List;

public class Enrollment {
    private final EnrollmentId id;
    private final StudentId studentId;
    private EnrollmentStatus status;
    private final List<EnrollmentConfirmedEvent> domainEvents = new ArrayList<>();

    private Enrollment(EnrollmentId id, StudentId studentId) {
        this.id = id;
        this.studentId = studentId;
        this.status = EnrollmentStatus.PENDING;
    }

    public static Enrollment create(EnrollmentId id, StudentId studentId) {
        return new Enrollment(id, studentId);
    }

    public void confirm() {
        if (status != EnrollmentStatus.PENDING) {
            throw new IllegalStateException("Only pending enrollments can be confirmed");
        }
        this.status = EnrollmentStatus.CONFIRMED;
        this.domainEvents.add(new EnrollmentConfirmedEvent(id.value(), studentId.value()));
    }

    public boolean isConfirmed() {
        return status == EnrollmentStatus.CONFIRMED;
    }

    public List<EnrollmentConfirmedEvent> domainEvents() {
        return List.copyOf(domainEvents);
    }

    public void clearDomainEvents() {
        domainEvents.clear();
    }
}
```

## Checklist

- [ ] The aggregate exposes no public setters
- [ ] Transitions validate the invariant before changing state
- [ ] Other aggregates are referenced by id
- [ ] Domain events are registered in the aggregate
- [ ] No framework annotations in the file
