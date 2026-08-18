# Value Objects

Location: `[context-name]/domain/model/valueobjects/`

- **Use Records:** Value objects should be Java records when appropriate.
- **Apply JPA Annotations:** Use `@Embeddable` for persistence.
- **Validation:** Include validation in compact constructors.
- **Immutable:** Value objects must remain immutable.
- **No unnecessary Lombok:** Do not use `@Getter` on records.

## Checklist

- [ ] Records used for value objects
- [ ] `@Embeddable` annotation applied where needed
- [ ] Validation logic in constructor
- [ ] Appropriate JPA column mappings
- [ ] Null checks and business rule validation
- [ ] Enums for predefined values where applicable

## Important

For aggregate roots, use the shared folder if your platform provides auditable base models.

## Example

```java
// File: [context-name]/domain/model/valueobjects/EntityId.java
package com.acme.center.platform.[context].domain.model.valueobjects;

import jakarta.persistence.Embeddable;

@Embeddable
public record EntityId(Long entityId) {
    public EntityId {
        if (entityId == null || entityId <= 0) {
            throw new IllegalArgumentException("Entity ID must be a positive number");
        }
    }
}
```
