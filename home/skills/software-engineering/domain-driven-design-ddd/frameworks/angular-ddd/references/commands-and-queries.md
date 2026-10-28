# Commands and Queries Implementation

## Commands. Location: `[context-name]/domain/model/commands/`

Commands represent explicit intentions to change state. They carry all required data for write operations.

- **Naming Convention:** File names end with `.command.ts`; exported type names end with `Command`.
- **Use Immutable Types:** Commands are plain immutable TypeScript types (`type` or `Readonly<{ ... }>`).
- **No Java-Bean Classes:** Strictly avoid classes with `private _property` and getters/setters.
- **Specific Naming:** Use explicit business intention naming (e.g., `CreateCourseCommand`, `PublishCourseCommand`).
- **Validation Ready:** Include all operation inputs and use value objects / branded types for identifiers and business-critical fields.

```typescript
// Example: [context-name]/domain/model/commands/create-course.command.ts
import { CategoryId } from '../valueobjects/category-id.value-object';

export type CreateCourseCommand = Readonly<{
  title: string;
  description: string;
  categoryId: CategoryId;
}>;
```

### Checklist
- [ ] All command files end with `.command.ts`
- [ ] Exported command names end with `Command`
- [ ] Defined as immutable types (`Readonly<T>`), not classes with getters/setters
- [ ] Specific business intention naming
- [ ] Value objects / branded types used for domain-critical fields
- [ ] All necessary operation data included

---

## Queries. Location: `[context-name]/domain/model/queries/`

Queries represent requests for information, search criteria, and pagination parameters.

- **Naming Convention:** File names end with `.query.ts`; exported type names end with `Query`.
- **Use Immutable Types:** Immutable query models (`Readonly<{ ... }>`).
- **Specific Naming:** Query names describe the exact read intention (e.g., `GetCoursesByCategoryQuery`).
- **Read-Only:** Queries never trigger state modification.
- **Filters and Pagination:** Define optional search and pagination parameters explicitly.

```typescript
// Example: [context-name]/domain/model/queries/get-courses.query.ts
export type GetCoursesQuery = Readonly<{
  categoryId?: number;
  searchTerm?: string;
  page?: number;
  pageSize?: number;
}>;
```

### Checklist
- [ ] All query files end with `.query.ts`
- [ ] Exported query names end with `Query`
- [ ] Specific and descriptive read intention
- [ ] Search, filter, and pagination parameters clearly defined
