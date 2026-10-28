# Value Objects

Location: `[context-name]/domain/model/valueobjects/`

- **Use Java records** when they fit the concept.
- **No framework annotations.** Value objects must not declare `@Embeddable`, `@Entity`, `@Column`, `@Id`, `@Convert`, JPA/Hibernate/Spring annotations, or persistence/web types. Persistence mapping is the responsibility of `infrastructure`.
- **Validation:** in the compact constructor.
- **Immutability:** value objects must remain immutable.
- **No Lombok on records.** Never add `@Getter`/`@Setter`/`@Data` to records.

```java
// File: [context-name]/domain/model/valueobjects/EntityId.java
package com.acme.center.platform.[context].domain.model.valueobjects;

public record EntityId(Long entityId) {
    public EntityId {
        if (entityId == null || entityId <= 0) {
            throw new IllegalArgumentException("Entity ID must be a positive number");
        }
    }
}
```

When JPA must persist the value object, the persistence side lives in `infrastructure/persistence/jpa/embeddables/`, and the mapping between `EntityId` (domain) and `EntityIdEmbeddable` (infrastructure) happens in an explicit mapper — never through an annotation on the domain class.

## Checklist

- [ ] Value object is a Java `record`
- [ ] No `@Embeddable` / `@Column` / `@Id` / JPA / Spring annotation in the file
- [ ] No `import jakarta.persistence.*` and no `import org.springframework.*`
- [ ] Validation runs in the compact constructor
- [ ] The value object is fully immutable
- [ ] Enums for predefined values where applicable
