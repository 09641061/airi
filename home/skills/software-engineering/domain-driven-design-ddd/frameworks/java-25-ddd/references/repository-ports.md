# Repository Ports and Persistence Adapters

A repository abstraction is useful when an application service needs aggregate-oriented persistence behind a stable boundary. **It is not a requirement to create an interface for every table or every CRUD feature.**

## Domain port (when justified)

In a rich model, around an aggregate root:

```java
// File: [context-name]/domain/repositories/EnrollmentRepository.java
package com.acme.center.platform.[context].domain.repositories;

import com.acme.center.platform.[context].domain.model.aggregates.Enrollment;
import com.acme.center.platform.[context].domain.model.valueobjects.EnrollmentId;

import java.util.Optional;

public interface EnrollmentRepository {
    Optional<Enrollment> findById(EnrollmentId id);
    Enrollment save(Enrollment enrollment);
}
```

The port uses domain types and Java types only: no Spring Data, JPA, `EntityManager`, `Pageable`, SQL, or persistence entities. Do not create repositories per table or child entity. Read-only projections that do not need aggregate behavior use an application/read port instead of an aggregate repository.

## Infrastructure adapter

The mapping lives in infrastructure:

```text
infrastructure/persistence/jpa/
  entities/EnrollmentJpaEntity.java
  repositories/EnrollmentSpringDataRepository.java
  adapters/EnrollmentRepositoryAdapter.java
  assemblers/EnrollmentPersistenceAssembler.java
  embeddables/EnrollmentIdEmbeddable.java
```

```java
@Repository
public class EnrollmentRepositoryAdapter implements EnrollmentRepository {
    private final EnrollmentSpringDataRepository springData;

    public EnrollmentRepositoryAdapter(EnrollmentSpringDataRepository springData) {
        this.springData = springData;
    }

    @Override
    public Optional<Enrollment> findById(EnrollmentId id) {
        return springData.findById(id.value())
                .map(EnrollmentPersistenceAssembler::toDomain);
    }

    @Override
    public Enrollment save(Enrollment enrollment) {
        var saved = springData.save(EnrollmentPersistenceAssembler.toEntity(enrollment));
        return EnrollmentPersistenceAssembler.toDomain(saved);
    }
}
```

Avoid a Spring Data interface that also implements the domain port through overloaded default `save` methods; the explicit adapter makes mapping and persistence-exception translation easier to see. Infrastructure may depend on domain types; the reverse dependency is prohibited.

## Simple CRUD alternative

When the model has no meaningful domain invariants and the feature is ordinary CRUD, a JPA model with a small application service is the lower-cost choice. In that design, document it explicitly as a pragmatic persistence-oriented model. Do not add an interface, adapter, mapper, and duplicate entity solely to satisfy a template.

## Checklist

- [ ] A port exists only where it provides a meaningful aggregate/application boundary
- [ ] Domain ports contain no framework or persistence types
- [ ] JPA entities and Spring Data repositories remain in infrastructure
- [ ] Mapping and persistence-exception translation remain in the adapter
- [ ] Read projections are not forced through aggregate reconstitution
- [ ] Critical mappings and constraints are tested against a database
