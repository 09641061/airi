# Domain Events

Location: `[context-name]/domain/model/events/`

Domain events represent important domain facts.

- **Naming Convention**: Files end with `Event`
- **Past Tense**: Event names in past tense
- **Immutable**: Events immutable after creation
- **Essential Data**: Include only necessary data, prefer IDs
- **Event separation**: Distinguish Domain Events vs Integration Events

## Checklist

- [ ] Event names end with `Event`
- [ ] Past tense naming convention
- [ ] Include occurrence timestamp
- [ ] Essential data only (prefer IDs)
- [ ] Immutable after creation
- [ ] Integration events defined separately if crossing contexts

## Outbox / integration events

When an event must cross bounded-context boundaries reliably, add the outbox pattern: persist the integration event in the same transaction as the domain change, then publish it asynchronously from an outbox relay. This guarantees at-least-once delivery without dual-write inconsistency.
