# Infrastructure Contracts & REST Resources

Location: `[context-name]/infrastructure/contracts/`

Contracts define request and response payloads exchanged with backend APIs. They are derived directly from documented OpenAPI / Swagger specifications.

- **Naming Convention:** Files end with `.contract.ts` or `.resource.ts`. Exported types use specific names (e.g., `CourseResource`, `CreateCourseRequest`).
- **No DTO Classes:** Strictly use immutable `type` or `interface`. No classes with constructors or getters/setters.
- **No Mapper Classes:** Do not create `Assembler` or `Mapper` classes when contracts match domain needs. Use simple pure transformation functions only when domain representations differ significantly from the transport payload.
- **Contract Fidelity:** Mirror the server's OpenAPI schemas accurately (including optional fields, nullability, and nested structures).

```typescript
// Example: [context-name]/infrastructure/contracts/course.contract.ts
export interface CourseResource {
  readonly id: number;
  readonly title: string;
  readonly description: string;
  readonly categoryId: number;
}

export interface CreateCourseRequest {
  readonly title: string;
  readonly description: string;
  readonly categoryId: number;
}
```

### Checklist
- [ ] Contracts are plain `type` or `interface` with `readonly` fields
- [ ] No DTO classes, constructors, or methods
- [ ] Accurately reflect OpenAPI / Swagger schemas
- [ ] Placed in `infrastructure/contracts/`
- [ ] Zero mapper classes; transformations (if needed) are pure functions
