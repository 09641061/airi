# Anti-Corruption Layer (ACL) — Cross-Context Integration

Use this whenever a bounded context needs data or operations from another bounded context. **Never call another context's internals directly** — always go through an ACL facade.

## Step 1: Identify Communication Needs

```
1. What data does Context A need from Context B?
2. What operations must Context A perform against Context B?
```

## Step 2: Map Domain Models

```
Context A (Consumer) Model <-> Context B (Provider) Model
```

## Step 3: Define ACL Interface Contract

```
Questions to define:
1. Which methods does the ACL facade expose?
2. Which parameters are needed?
3. Which return types make business sense?
4. How are failures translated?

Design principle: Keep it simple and focused on consumer needs.
```

## Implementation in Provider Context (Context B)

**Step 4: Create ACL Facade Interface**

```java
// File: [context-b]/interfaces/acl/[ContextB]ContextFacade.java
package com.acme.center.platform.[contextb].interfaces.acl;

import java.util.Optional;

public interface [ContextB]ContextFacade {

    Optional<Long> create[Entity](String param1, String param2);

    Optional<Long> find[Entity]IdBy[Field](String identifier);
}
```

**Step 5: Implement ACL Facade**

```java
// File: [context-b]/application/acl/[ContextB]ContextFacadeImpl.java
package com.acme.center.platform.[contextb].application.acl;

import com.acme.center.platform.[contextb].domain.model.commands.Create[Entity]Command;
import com.acme.center.platform.[contextb].domain.model.queries.Get[Entity]By[Field]Query;
import com.acme.center.platform.[contextb].domain.services.[Entity]CommandService;
import com.acme.center.platform.[contextb].domain.services.[Entity]QueryService;
import com.acme.center.platform.[contextb].interfaces.acl.[ContextB]ContextFacade;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class [ContextB]ContextFacadeImpl implements [ContextB]ContextFacade {

    private final [Entity]CommandService [entity]CommandService;
    private final [Entity]QueryService [entity]QueryService;

    public [ContextB]ContextFacadeImpl(
            [Entity]CommandService [entity]CommandService,
            [Entity]QueryService [entity]QueryService
    ) {
        this.[entity]CommandService = [entity]CommandService;
        this.[entity]QueryService = [entity]QueryService;
    }

    @Override
    public Optional<Long> create[Entity](String param1, String param2) {
        var command = new Create[Entity]Command(param1, param2);
        return [entity]CommandService.handle(command).map(entity -> entity.getId());
    }

    @Override
    public Optional<Long> find[Entity]IdBy[Field](String identifier) {
        var query = new Get[Entity]By[Field]Query(new [Field](identifier));
        return [entity]QueryService.handle(query).map(entity -> entity.getId());
    }
}
```

## Implementation in Consumer Context (Context A)

**Step 6: Create Value Objects in Consumer Context**

```java
// File: [context-a]/domain/model/valueobjects/[Entity]Id.java
package com.acme.center.platform.[contexta].domain.model.valueobjects;

import jakarta.persistence.Embeddable;

@Embeddable
public record [Entity]Id(Long [entity]Id) {
    public [Entity]Id {
        if ([entity]Id == null || [entity]Id <= 0) {
            throw new IllegalArgumentException("[Entity] ID must be a positive number");
        }
    }
}
```

**Step 7: Create External Service (ACL Layer)**

```java
// File: [context-a]/application/internal/outboundservices/acl/External[Entity]Service.java
package com.acme.center.platform.[contexta].application.internal.outboundservices.acl;

import com.acme.center.platform.[contexta].domain.model.valueobjects.[Entity]Id;
import com.acme.center.platform.[contextb].interfaces.acl.[ContextB]ContextFacade;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class External[Entity]Service {

    private final [ContextB]ContextFacade [contextb]ContextFacade;

    public External[Entity]Service([ContextB]ContextFacade [contextb]ContextFacade) {
        this.[contextb]ContextFacade = [contextb]ContextFacade;
    }

    public Optional<[Entity]Id> fetch[Entity]By[Field](String [field]) {
        return [contextb]ContextFacade
                .find[Entity]IdBy[Field]([field])
                .map([Entity]Id::new);
    }

    public Optional<[Entity]Id> create[Entity](String param1, String param2) {
        return [contextb]ContextFacade
                .create[Entity](param1, param2)
                .map([Entity]Id::new);
    }
}
```

**Step 8: Update Command Services (Integration in Consumer Context)**

```java
// File: [context-a]/application/internal/commandservices/[ConsumerEntity]CommandServiceImpl.java

private final External[Entity]Service external[Entity]Service;

public [ConsumerEntity]CommandServiceImpl(
        [ConsumerEntity]Repository repository,
        External[Entity]Service external[Entity]Service
) {
    this.repository = repository;
    this.external[Entity]Service = external[Entity]Service;
}

@Override
public [ConsumerEntity]Id handle(Create[ConsumerEntity]Command command) {
    var [entity]Id = external[Entity]Service.fetch[Entity]By[Field](command.[field]())
            .or(() -> external[Entity]Service.create[Entity](command.param1(), command.param2()));

    var resolvedId = [entity]Id.orElseThrow(() ->
            new IllegalStateException("Unable to create/fetch external entity"));

    repository.findBy[Entity]Id(resolvedId).ifPresent(existing -> {
        throw new IllegalArgumentException("Duplicate entity found");
    });

    var [consumerEntity] = new [ConsumerEntity](resolvedId);
    repository.save([consumerEntity]);
    return [consumerEntity].getId();
}
```

## Common Pitfalls to Avoid

1. **Do not expose complex domain objects** — use simple ACL contracts.
2. **Do not create circular dependencies** — keep direction explicit.
3. **Do not skip error translation** — map external errors to domain-level errors.
4. **Do not skip testing** — include ACL contract and integration tests.
5. **Do not tight-couple contexts** — always integrate through ACL, never direct internal calls.
6. **Do not use sentinel values** — use `Optional`/typed errors, never `0L` as not-found.
