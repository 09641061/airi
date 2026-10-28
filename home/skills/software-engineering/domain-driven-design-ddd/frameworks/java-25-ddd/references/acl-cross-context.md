# ACL and Cross-Context Communication

Use a context-owned contract whenever one bounded context needs another's capabilities. An **Anti-Corruption Layer (ACL)** is a consumer-side translation/protection boundary; it is not synonymous with every facade or every in-process method call.

## Dependency direction

- The provider exposes a small, stable **application API/input port**, for example `profiles/application/api/ProfilesApi`. Its implementation belongs to the provider's application layer.
- The consumer expresses the need in its own application layer, for example `learning/application/ports/out/ProfileDirectory`.
- A consumer-side adapter/ACL implements that need and translates the provider's published types into consumer-owned types. It belongs in `infrastructure` (or the project's clearly defined outbound-adapter package).
- **Do not** put the provider contract in an outer HTTP/interface-adapter package when the provider application must import and implement it: that reverses the dependency direction.
- Never import another context's private aggregate, persistence entity, Spring Data repository, or implementation service.

```java
// Provider: [context-b]/application/api/ProfilesApi.java
package com.acme.center.platform.[contextb].application.api;

import java.util.Optional;

public interface ProfilesApi {
    Optional<Long> findProfileIdByEmail(String email);
}
```

```java
// Consumer port: [context-a]/application/ports/out/ProfileDirectory.java
package com.acme.center.platform.[contexta].application.ports.out;

import com.acme.center.platform.[contexta].domain.model.valueobjects.ProfileId;

import java.util.Optional;

public interface ProfileDirectory {
    Optional<ProfileId> findProfileByEmail(String email);
}
```

```java
// Consumer adapter/ACL: [context-a]/infrastructure/acl/ProfilesModuleAdapter.java
package com.acme.center.platform.[contexta].infrastructure.acl;

import com.acme.center.platform.[contexta].application.ports.out.ProfileDirectory;
import com.acme.center.platform.[contexta].domain.model.valueobjects.ProfileId;
import com.acme.center.platform.[contextb].application.api.ProfilesApi;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class ProfilesModuleAdapter implements ProfileDirectory {
    private final ProfilesApi profilesApi;

    public ProfilesModuleAdapter(ProfilesApi profilesApi) {
        this.profilesApi = profilesApi;
    }

    @Override
    public Optional<ProfileId> findProfileByEmail(String email) {
        return profilesApi.findProfileIdByEmail(email).map(ProfileId::new);
    }
}
```

For two modules in the same deployable, a direct call through the provider's public application API may be enough when no semantic translation is required. Add an ACL when it protects the consumer from a foreign model or protocol; do not add a layer that only renames fields.

## Events between contexts

An integration event keeps its contract separate from the provider's internal domain event and includes only what consumers need. A synchronous in-process Spring event is neither durable nor automatically asynchronous: when delivery must survive process failure, write the outbox record in the same transaction as the state change and publish it through a retrying relay (at-least-once delivery means idempotent consumers).

## Common pitfalls to avoid

1. **Do not expose complex domain objects** — use minimal ACL contracts.
2. **Do not create circular dependencies** — keep the direction explicit.
3. **Do not skip error translation** — map external errors to consumer-level errors.
4. **Do not use sentinel values** — use `Optional`/typed errors, never `0L` as "not found".
5. **Do not tight-couple contexts** — integrate through the contract, never by calling an internal implementation directly.
6. **Do not add an outbox without a need** — only when durable delivery is a requirement.

## Checklist

- [ ] The provider owns the public application contract
- [ ] The consumer expresses its need through a consumer-owned outbound port when useful
- [ ] The ACL translates semantics rather than merely renaming fields
- [ ] No provider persistence or private domain types cross the boundary
- [ ] Absence and failure are represented explicitly, never by sentinels
- [ ] Synchronous call, local event, or durable outbox is chosen according to consistency and reliability requirements
- [ ] Contract, mapping, error, and retry behavior are tested at the relevant boundary
