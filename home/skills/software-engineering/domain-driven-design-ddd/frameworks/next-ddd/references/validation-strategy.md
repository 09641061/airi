# Validation Strategy

[Skill overview and workflow](../SKILL.md). Examples target Next.js 16 and React 19.3; verify project versions.

## Validation Strategy

Use schemas at input boundaries in `interfaces/schemas/`, not as the domain itself.

1. **Schema validation**: form data, route params, query strings, and incoming HTTP payloads.
2. **Business rules**: Spring enforces authoritative invariants for remote features, including calls bypassing the UI. An optional rich local Domain also protects its own invariants.
3. **Provider response validation**: Infrastructure validates untrusted external data before translating it inward; generated OpenAPI TypeScript types alone do not validate runtime JSON.

```ts
// interfaces/schemas/create-product.schema.ts
import { z } from 'zod'

export const createProductSchema = z.object({
  name: z.string().trim().min(1).max(120),
  categoryId: z.string().trim().min(1),
})

export type CreateProductInput = z.infer<typeof createProductSchema>
```

The remote schema’s 120-character limit is its input/API contract, not an import from the optional local Domain. In the separate rich-domain example, its boundary schema reuses `PRODUCT_NAME_MAX_LENGTH`. Prefer runtime schemas generated from the authoritative OpenAPI contract. For this manually maintained remote schema and the form’s `maxLength={120}`, contract tests must detect drift in constraints (including length, required fields, and normalization) against Spring. Keep generated transport artifacts in Infrastructure; expose a browser-safe boundary schema through an explicit edge adaptation, never import transport types into Domain or Application. The optional local invariant remains independent.

Forms can reuse a browser-safe input schema for feedback, but the server must validate again. Expected validation failures should become stable field or form errors, not uncaught parse exceptions.
