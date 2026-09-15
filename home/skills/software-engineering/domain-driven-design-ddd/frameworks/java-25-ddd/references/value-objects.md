# Value Objects

Location: `[context-name]/domain/model/valueobjects/`

- **Use Java records** for value objects.
- **No framework annotations.** Value objects must not declare `@Embeddable`, `@Entity`, `@Column`, `@Id`, `@Convert`, JPA/Hibernate/Spring annotations, or any persistence or web type. Persistence mapping is the responsibility of the infrastructure layer.
- **Validation:** include validation in compact constructors.
- **Immutability:** value objects must remain immutable.
- **No Lombok on records.** Do not add `@Getter`/`@Setter`/`@Data` on records.

## Layer boundary reminder

A domain value object lives in `domain/`, knows only the ubiquitous language, and never imports anything from `infrastructure/`. When JPA must persist the object, the persistence-side `@Embeddable` (or JPA converter) lives in `infrastructure/persistence/jpa/embeddables/` and is mapped to/from the domain value object by an explicit mapper — never by an annotation in the domain class.

## Checklist

- [ ] Value object is a Java `record`
- [ ] No `@Embeddable` / `@Column` / `@Id` / JPA / Spring annotation is present in the file
- [ ] No `import jakarta.persistence.*` or `import org.springframework.*` in the file
- [ ] Validation runs in the compact constructor
- [ ] The value object is fully immutable
- [ ] Enums for predefined values are used where applicable

## Example

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

> Persistence side (infrastructure, NOT shown here):
> ```java
> // File: [context-name]/infrastructure/persistence/jpa/embeddables/EntityIdEmbeddable.java
> package com.acme.center.platform.[context].infrastructure.persistence.jpa.embeddables;
>
> import jakarta.persistence.Embeddable;
> import java.io.Serializable;
>
> @Embeddable
> public class EntityIdEmbeddable implements Serializable {
>     private Long entityId;
>     protected EntityIdEmbeddable() { }
>     public EntityIdEmbeddable(Long entityId) { this.entityId = entityId; }
>     public Long getEntityId() { return entityId; }
> }
> ```
> The mapper between `EntityId` (domain) and `EntityIdEmbeddable` (infrastructure) is the only place both types meet.
