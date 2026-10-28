# Value Objects Implementation

Location: `[context-name]/domain/model/valueobjects/`

Value objects represent immutable, validated domain concepts used across commands, queries, entities, and UI logic.

- **Branded Types Preferred:** Implement value objects using TypeScript **Branded Types** (`type EntityId = number & { readonly __brand: unique symbol }`) or plain immutable types. This ensures compile-time type safety without the runtime overhead or form-binding friction of object wrappers like `{ value: T }`.
- **Pure Validation/Parsing Functions:** Accompany each value object with a pure parser/factory function that validates business constraints and returns the branded type.
- **Immutable:** Value objects are strictly immutable (`Readonly<T>`).
- **No Class Boilerplate:** Avoid Java-like classes with private fields, getters, and setters.
- **Null Safety:** Creator functions must assert constraints (e.g., positive integer, regex format, non-empty string) and throw explicit domain errors on invalid values.

```typescript
// Example: [context-name]/domain/model/valueobjects/course-id.value-object.ts
export type CourseId = number & { readonly __brand: unique symbol };

export const parseCourseId = (value: number): CourseId => {
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error('Course ID must be a positive integer');
  }
  return value as CourseId;
};
```

### Checklist
- [ ] Value objects use branded types or immutable TypeScript `type`/`interface`
- [ ] Pure validation/parser functions validate domain constraints
- [ ] No `{ value: T }` object wrapping unless conceptually required
- [ ] Immutable by design (`Readonly<T>`)
- [ ] Reusable ID/audit fields derived from shared core where applicable
