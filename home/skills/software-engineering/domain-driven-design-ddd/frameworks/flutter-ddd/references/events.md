# Events Implementation

Location: `[context-name]/domain/model/events/`

Domain events capture meaningful domain facts that happened in past tense.

- **Naming Convention:** File names end with `.event.dart`; exported names end with `Event`.
- **Use Immutable Classes:** Event payloads are immutable.
- **Past Tense:** Event names must be in past tense.
- **Essential Data:** Keep only required IDs and context.

-  Events are immutable classes
-  File names end with `.event.dart`
-  Event names end with `Event` and use past tense
-  `occurredOn` timestamp included
-  Essential data only (prefer IDs)
-  No Flutter framework references inside event models
