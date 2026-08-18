# ACL Implementation (Cross-Context Communication)

**Step 1: Identify Communication Needs**

```
1. What data does Context A need from Context B?

2. What operations does Context A need to perform on Context B?
```

**Step 2: Map Domain Models**

```
Context A (Consumer) Model <-> Context B (Provider) Model
```

**Step 3: Define ACL Interface Contract**

```
Questions to define:

1. What methods will the facade expose?

2. What parameters are needed?

3. What return types make sense?

4. How to handle errors?

Design principle: Keep it simple and focused on consumer needs
```

## Implementation in Provider Context (Context B)

**Step 4: Create ACL Facade Interface**

```ts
// File: [context-b]/interfaces/acl/[context-b]-context-facade.ts

export interface ContextBContextFacade {
  createEntity(param1: string, param2: string): Promise<number>;
  findEntityIdByField(identifier: string): Promise<number>;
}
```

**Step 5: Implement ACL Facade**

```ts
// File: [context-b]/application/acl/[context-b]-context-facade.impl.ts

import { Injectable, inject } from '@angular/core';
import { ContextBContextFacade } from '../../interfaces/acl/context-b-context-facade';
import { EntityCommandService } from '../internal/commandservices/entity-command-service';
import { EntityQueryService } from '../internal/queryservices/entity-query-service';

@Injectable({ providedIn: 'root' })
export class ContextBContextFacadeImpl implements ContextBContextFacade {
  private readonly entityCommandService = inject(EntityCommandService);
  private readonly entityQueryService = inject(EntityQueryService);

  async createEntity(param1: string, param2: string): Promise<number> {
    const entity = await this.entityCommandService.handle({ param1, param2 });
    return entity ? entity.id : 0;
  }

  async findEntityIdByField(identifier: string): Promise<number> {
    const entity = await this.entityQueryService.handle({ identifier });
    return entity ? entity.id : 0;
  }
}
```

## Implementation in Consumer Context (Context A)

**Step 6: Create Value Objects in Consumer Context**

```ts
// File: [context-a]/domain/model/valueobjects/entity-id.value-object.ts

export type EntityId = Readonly<{ value: number }>;

export const createEntityId = (entityId: number): EntityId => {
  if (!Number.isInteger(entityId) || entityId <= 0) {
    throw new Error('Entity ID must be a positive number');
  }
  return Object.freeze({ value: entityId });
};
```

**Step 7: Create External Service (ACL Layer)**

```ts
// File: [context-a]/application/internal/outboundservices/acl/external-entity.service.ts

import { Injectable, inject } from '@angular/core';
import { ContextBContextFacade } from '../../../../context-b/interfaces/acl/context-b-context-facade';
import { EntityId, createEntityId } from '../../../domain/model/valueobjects/entity-id.value-object';

@Injectable({ providedIn: 'root' })
export class ExternalEntityService {
  private readonly contextBContextFacade = inject(ContextBContextFacade);

  async fetchEntityByField(field: string): Promise<EntityId | null> {
    const entityId = await this.contextBContextFacade.findEntityIdByField(field);
    return entityId === 0 ? null : createEntityId(entityId);
  }

  async createEntity(param1: string, param2: string): Promise<EntityId | null> {
    const entityId = await this.contextBContextFacade.createEntity(param1, param2);
    return entityId === 0 ? null : createEntityId(entityId);
  }
}
```

## Phase 4: Integration in Consumer Context

**Step 8: Update Command Services**

```ts
// File: [context-a]/application/internal/commandservices/[consumer-entity]-command-service.impl.ts

export class ConsumerEntityCommandServiceImpl {
  private readonly repository = inject(ConsumerEntityRepository);
  private readonly externalEntityService = inject(ExternalEntityService);

  async handle(command: CreateConsumerEntityCommand): Promise<ConsumerEntityId> {
    // Step 1: Try to fetch existing entity from external context
    let entityId = await this.externalEntityService.fetchEntityByField(command.field);

    // Step 2: If not found, create in external context
    if (!entityId) {
      entityId = await this.externalEntityService.createEntity(command.param1, command.param2);
    } else {
      // Step 3: Validate no duplicate exists in current context
      const existing = await this.repository.findByEntityId(entityId);
      if (existing) throw new Error('Duplicate entity found');
    }

    // Step 4: Ensure external operation succeeded
    if (!entityId) throw new Error('Unable to create/fetch external entity');

    // Step 5: Create consumer entity with external reference
    const consumerEntity = ConsumerEntity.create(entityId);
    await this.repository.save(consumerEntity);
    return consumerEntity.id;
  }
}
```

**Common Pitfalls to Avoid:**

1. **Don't expose complex domain objects** - Use simple types in ACL interfaces.
2. **Don't create circular dependencies** - Context A -> Context B, not both ways.
3. **Don't skip error handling** - Always handle external context failures.
4. **Don't forget testing** - Test ACL integration thoroughly.
5. **Don't tight-couple** - Always go through ACL interfaces/facades, never direct calls.
6. **Don't mix DI styles** - Once a bounded context adopts `inject()`, don't reintroduce constructor-parameter injection; keep it consistent across services, guards, and interceptors.
