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

```dart
// File: [context_b]/interfaces/acl/context_b_context_facade.dart

abstract class ContextBContextFacade {
  Future<int> createEntity(String param1, String param2);
  Future<int?> findEntityIdByField(String identifier);
}
```

**Step 5: Implement ACL Facade**

```dart
// File: [context_b]/application/acl/context_b_context_facade_impl.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../interfaces/acl/context_b_context_facade.dart';
import '../internal/commandservices/entity_command_service.dart';
import '../internal/queryservices/entity_query_service.dart';

part 'context_b_context_facade_impl.g.dart';

class ContextBContextFacadeImpl implements ContextBContextFacade {
  ContextBContextFacadeImpl(this._entityCommandService, this._entityQueryService);

  final EntityCommandService _entityCommandService;
  final EntityQueryService _entityQueryService;

  @override
  Future<int> createEntity(String param1, String param2) async {
    final entity = await _entityCommandService.handle(
      CreateEntityCommand(param1: param1, param2: param2),
    );
    return entity?.id ?? 0;
  }

  @override
  Future<int?> findEntityIdByField(String identifier) async {
    final entity = await _entityQueryService.handle(
      FindEntityByFieldQuery(identifier: identifier),
    );
    return entity?.id;
  }
}

@riverpod
ContextBContextFacade contextBContextFacade(Ref ref) {
  return ContextBContextFacadeImpl(
    ref.watch(entityCommandServiceProvider),
    ref.watch(entityQueryServiceProvider),
  );
}
```

## Implementation in Consumer Context (Context A)

**Step 6: Create Value Objects in Consumer Context**

```dart
// File: [context_a]/domain/model/valueobjects/entity_id.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity_id.freezed.dart';

@freezed
sealed class EntityId with _$EntityId {
  const factory EntityId(int value) = _EntityId;

  factory EntityId.create(int entityId) {
    if (entityId <= 0) {
      throw ArgumentError('Entity ID must be a positive number');
    }
    return EntityId(entityId);
  }
}
```

**Step 7: Create External Service (ACL Layer)**

```dart
// File: [context_a]/application/internal/outboundservices/acl/external_entity_service.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../context_b/interfaces/acl/context_b_context_facade.dart';
import '../../../domain/model/valueobjects/entity_id.dart';

part 'external_entity_service.g.dart';

class ExternalEntityService {
  ExternalEntityService(this._contextBContextFacade);

  final ContextBContextFacade _contextBContextFacade;

  Future<EntityId?> fetchEntityByField(String field) async {
    final entityId = await _contextBContextFacade.findEntityIdByField(field);
    return entityId == null ? null : EntityId.create(entityId);
  }

  Future<EntityId?> createEntity(String param1, String param2) async {
    final entityId = await _contextBContextFacade.createEntity(param1, param2);
    return entityId == 0 ? null : EntityId.create(entityId);
  }
}

@riverpod
ExternalEntityService externalEntityService(Ref ref) {
  return ExternalEntityService(ref.watch(contextBContextFacadeProvider));
}
```

## Phase 4: Integration in Consumer Context

**Step 8: Update Command Services**

```dart
// File: [context_a]/application/internal/commandservices/consumer_entity_command_service_impl.dart

class ConsumerEntityCommandServiceImpl implements ConsumerEntityCommandService {
  ConsumerEntityCommandServiceImpl(this._repository, this._externalEntityService);

  final ConsumerEntityRepository _repository;
  final ExternalEntityService _externalEntityService;

  @override
  Future<ConsumerEntityId> handle(CreateConsumerEntityCommand command) async {
    // Step 1: Try to fetch existing entity from external context
    var entityId = await _externalEntityService.fetchEntityByField(command.field);

    // Step 2: If not found, create in external context
    if (entityId == null) {
      entityId = await _externalEntityService.createEntity(command.param1, command.param2);
    } else {
      // Step 3: Validate no duplicate exists in current context
      final existing = await _repository.findByEntityId(entityId);
      if (existing != null) throw StateError('Duplicate entity found');
    }

    // Step 4: Ensure external operation succeeded
    if (entityId == null) throw StateError('Unable to create/fetch external entity');

    // Step 5: Create consumer entity with external reference
    final consumerEntity = ConsumerEntity.create(entityId);
    await _repository.save(consumerEntity);
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
6. **Don't mix DI styles** - Once a bounded context adopts Riverpod codegen, don't reintroduce manual `GetIt` registration or `Provider`-package wiring; keep it consistent across services, facades, and widgets.
