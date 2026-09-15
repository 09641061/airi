# Repositories: domain port + infrastructure adapter

Repositories are split into two files: a **port** (domain interface) and an **adapter** (infrastructure implementation). The port is what the application code depends on; the adapter is what the database driver talks to.

## Port — domain layer

Location: `[context-name]/domain/repositories/`

- One port **per aggregate root** — never per table, never per child entity.
- The port is a plain Java interface with **no Spring, no JPA, no framework imports**.
- It receives and returns whole aggregates and value objects only. It never exposes `JpaRepository`, `Pageable`, `EntityManager`, `IQueryable`, ORM criteria, or any persistence abstraction.
- Method names speak the ubiquitous language (`findByOrderNumber`, not `findByOrderNumJPQL`).
- The collection semantics are minimal: `save(aggregate)`, `findById(valueObjectId)`, `delete(aggregate)`, plus aggregate-specific finders when needed.

### Example

```java
// File: [context-name]/domain/repositories/CargoRepository.java
package com.acme.center.platform.cargo.domain.repositories;

import com.acme.center.platform.cargo.domain.model.aggregates.Cargo;
import com.acme.center.platform.cargo.domain.model.valueobjects.TrackingId;
import java.util.Optional;

public interface CargoRepository {
    void save(Cargo cargo);
    Optional<Cargo> findByTrackingId(TrackingId trackingId);
}
```

## Adapter — infrastructure layer

Location: `[context-name]/infrastructure/persistence/jpa/repositories/`

- Implements the **domain port** above. Spring Data JPA may be used internally.
- Extends `JpaRepository<CargoJpaEntity, Long>` (or a custom fragment) for the technical plumbing; the port never sees this type.
- Annotated with `@Repository` so Spring picks it up.
- Depends on an internal mapper between the JPA entity (`CargoJpaEntity`, in `infrastructure/persistence/jpa/entities/`) and the domain aggregate (`Cargo`, in `domain/model/aggregates/`).
- Maps through `CargoMapper.toDomain(entity)` (calling the aggregate's `reconstitute` factory path) and `CargoMapper.toJpa(aggregate)`. The mapper belongs to infrastructure, never to the domain.

### Example

```java
// File: [context-name]/infrastructure/persistence/jpa/repositories/JpaCargoRepository.java
package com.acme.center.platform.cargo.infrastructure.persistence.jpa.repositories;

import com.acme.center.platform.cargo.domain.repositories.CargoRepository;
import com.acme.center.platform.cargo.domain.model.aggregates.Cargo;
import com.acme.center.platform.cargo.domain.model.valueobjects.TrackingId;
import com.acme.center.platform.cargo.infrastructure.persistence.jpa.entities.CargoJpaEntity;
import com.acme.center.platform.cargo.infrastructure.persistence.jpa.mappers.CargoMapper;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface JpaCargoRepository
        extends JpaRepository<CargoJpaEntity, Long>, CargoRepository {

    @Override
    default void save(Cargo cargo) {
        save(CargoMapper.toJpa(cargo));
    }

    @Override
    default Optional<Cargo> findByTrackingId(TrackingId trackingId) {
        return findByCargoTrackingId(trackingId.value())
                   .map(CargoMapper::toDomain);
    }

    Optional<CargoJpaEntity> findByCargoTrackingId(String trackingId);
}
```

## Testing split

- **Domain port tests** — none (the port is an interface; it is tested through the application service that uses it, with a stub/mock of the port).
- **Infrastructure adapter tests** — integration tests, marked separately, that exercise real SQL/PostgreSQL with a test database (Testcontainers, embedded, or in-memory mode). Unit tests with Mockito on `JpaRepository` are discouraged — they exercise Spring Data defaults, not your code.

## Checklist

- [ ] Domain port interface lives in `domain/repositories/`
- [ ] Domain port imports nothing from `org.springframework.*` or `jakarta.persistence.*`
- [ ] One port per aggregate root; child entities have no port
- [ ] Method names use the ubiquitous language
- [ ] Adapter lives in `infrastructure/persistence/jpa/repositories/`, implements the domain port
- [ ] Mapper between JPA entity and domain aggregate lives in `infrastructure/persistence/jpa/mappers/`
- [ ] Adapter is the only place where `JpaRepository`, `@Repository`, `@Query` and JPA types appear
