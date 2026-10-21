# Domain Events

## 4. Events Implementation

**Location:** `[context-name]/domain/model/events/`

Domain Events describe something **that already happened**.

- **Naming:** `[Entity][PastAction]Event`; files end in `_event.go`.
- **Use structs** containing the event's essential data.
- **Include timestamp** and an event/aggregate ID when relevant.
- **Do not change events** after creation.
- **Separate** internal Domain Events from Integration Events published outside the context.

- [ ] Event types end in `Event`.
- [ ] Names use the past tense.
- [ ] Occurrence time included.
- [ ] Only required data is stored; prefer IDs.
- [ ] Payload treated as immutable.
- [ ] External integration events are versioned separately when needed.

---
