# ACL Implementation (Cross-Context Communication)

When a Bounded Context needs data or actions from another Bounded Context, they must communicate via an **Anti-Corruption Layer (ACL)**. Contexts must never import internal models, stores, or gateways from another context directly.

## Step 1: Identify Communication Needs

```
1. What data does Context A (Consumer) need from Context B (Provider)?
2. What operations does Context A need to perform on Context B?
```

## Step 2: Map Domain Models

```
Context A (Consumer) Model <---> Context B (Provider) Model
```

## Step 3: Define ACL Interface Contract

Keep it simple and focused strictly on consumer needs:
- What methods does the facade expose?
- What parameters are required?
- What return types make sense?

---

## Implementation in Provider Context (Context B)

### Step 4: Create ACL Facade Contract and Injection Token

Interfaces are erased at runtime in TypeScript and cannot serve as Angular DI tokens directly. Define an `InjectionToken` for the contract:

```typescript
// File: [context-b]/acl/[context-b]-context-facade.ts
export interface ContextBContextFacade {
  createEntity(param1: string, param2: string): Promise<number>;
  findEntityIdByField(identifier: string): Promise<number | null>;
}
```

```typescript
// File: [context-b]/acl/[context-b]-context-facade.token.ts
import { InjectionToken } from '@angular/core';
import { ContextBContextFacade } from './[context-b]-context-facade';

export const CONTEXT_B_CONTEXT_FACADE = new InjectionToken<ContextBContextFacade>(
  'ContextBContextFacade'
);
```

### Step 5: Implement ACL Facade

```typescript
// File: [context-b]/acl/[context-b]-context-facade.impl.ts
import { Injectable, inject, EnvironmentProviders, makeEnvironmentProviders } from '@angular/core';
import { ContextBContextFacade } from './[context-b]-context-facade';
import { CONTEXT_B_CONTEXT_FACADE } from './[context-b]-context-facade.token';
import { EntityStore } from '../application/entity.store';

@Injectable({ providedIn: 'root' })
export class ContextBContextFacadeImpl implements ContextBContextFacade {
  private readonly entityStore = inject(EntityStore);

  async createEntity(param1: string, param2: string): Promise<number> {
    const created = await this.entityStore.addEntity({ param1, param2 });
    return created ? created.id : 0;
  }

  async findEntityIdByField(identifier: string): Promise<number | null> {
    const entity = await this.entityStore.findByIdentifier(identifier);
    return entity ? entity.id : null;
  }
}

export function provideContextBFacade(): EnvironmentProviders {
  return makeEnvironmentProviders([
    { provide: CONTEXT_B_CONTEXT_FACADE, useExisting: ContextBContextFacadeImpl }
  ]);
}
```

---

## Implementation in Consumer Context (Context A)

### Step 6: Define Value Objects in Consumer Context

Use branded types or pure parsers so Context A does not leak Context B's raw types:

```typescript
// File: [context-a]/domain/model/valueobjects/external-entity-id.value-object.ts
export type ExternalEntityId = number & { readonly __brand: unique symbol };

export const parseExternalEntityId = (value: number): ExternalEntityId => {
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error('External entity ID must be a positive integer');
  }
  return value as ExternalEntityId;
};
```

### Step 7: Create Outbound Adapter (ACL Layer in Context A)

```typescript
// File: [context-a]/application/acl/external-entity.adapter.ts
import { Injectable, inject } from '@angular/core';
import { CONTEXT_B_CONTEXT_FACADE } from '../../../../context-b/acl/[context-b]-context-facade.token';
import { ExternalEntityId, parseExternalEntityId } from '../../domain/model/valueobjects/external-entity-id.value-object';

@Injectable({ providedIn: 'root' })
export class ExternalEntityAdapter {
  private readonly facade = inject(CONTEXT_B_CONTEXT_FACADE);

  async fetchEntityId(field: string): Promise<ExternalEntityId | null> {
    const rawId = await this.facade.findEntityIdByField(field);
    return rawId ? parseExternalEntityId(rawId) : null;
  }

  async createEntity(param1: string, param2: string): Promise<ExternalEntityId> {
    const rawId = await this.facade.createEntity(param1, param2);
    if (!rawId) throw new Error('External context failed to create entity');
    return parseExternalEntityId(rawId);
  }
}
```

### Step 8: Use in Consumer Application Service / Store

```typescript
// File: [context-a]/application/consumer-entity.store.ts
import { Injectable, inject } from '@angular/core';
import { ConsumerEntityGateway } from '../infrastructure/gateways/consumer-entity.gateway';
import { ExternalEntityAdapter } from './acl/external-entity.adapter';
import { CreateConsumerEntityCommand } from '../domain/model/commands/create-consumer-entity.command';

@Injectable({ providedIn: 'root' })
export class ConsumerEntityStore {
  private readonly gateway = inject(ConsumerEntityGateway);
  private readonly externalAdapter = inject(ExternalEntityAdapter);

  async handleCreate(command: CreateConsumerEntityCommand): Promise<void> {
    // 1. Resolve or create dependency in external context via ACL
    let externalId = await this.externalAdapter.fetchEntityId(command.field);
    if (!externalId) {
      externalId = await this.externalAdapter.createEntity(command.param1, command.param2);
    }

    // 2. Persist local entity via gateway with reference to externalId
    await this.gateway.create({ ...command, externalId });
  }
}
```

---

## Pitfalls to Avoid
1. **Never import internals cross-context:** Never import models, stores, or gateways from another bounded context directly. Always pass through the ACL Facade.
2. **No Repositories:** Use gateways and stores; do not inject simulated database repositories.
3. **Circular Dependencies:** Context A $\to$ Context B, never bidirectional.
4. **Error Isolation:** Handle external context failures gracefully inside the adapter.
