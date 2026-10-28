# Domain Events

Location: `[context-name]/domain/model/events/`

A domain event is an immutable fact that has already occurred in one bounded context. It is a plain Java type: it **does not** extend `ApplicationEvent` and does not import messaging or persistence frameworks.

- **Past-tense name:** `TutorialCompleted`, `ProfileCreated`.
- **Essential data only:** prefer stable identifiers over whole aggregates or unnecessary personal data.
- **Timestamp** only when the contract needs one.
- **Domain events are not integration events:** an integration event is the contract published by the provider for other contexts.

```java
// File: [context-name]/domain/model/events/EnrollmentConfirmedEvent.java
package com.acme.center.platform.[context].domain.model.events;

public record EnrollmentConfirmedEvent(Long enrollmentId, Long studentId) {
}
```

A domain event is a plain immutable Java type; delivery (Spring events, outbox) is an application/infrastructure concern and never part of the domain type.

## Checklist

- [ ] Domain event is a plain immutable Java type
- [ ] Only the data consumers need
- [ ] Integration-event contract is separate from the internal domain event
- [ ] Publication and transaction timing are explicit
- [ ] Outbox only when delivery must be durable
- [ ] Consumers are idempotent where retries are possible
