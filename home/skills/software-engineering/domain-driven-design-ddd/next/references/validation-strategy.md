# Validation Strategy

Use schemas at the boundary, not as the domain itself.

## Good split

1. **Schema validation**: incoming form data, route params, API payloads.
2. **Domain rules**: invariants, consistency, behavior, and business constraints.

```ts
import { z } from 'zod'

export const createProductSchema = z.object({
  name: z.string().min(1).max(120),
  categoryId: z.string().min(1),
})

export type CreateProductInput = z.infer<typeof createProductSchema>
```

Place transport schemas in `interfaces/rest/schemas/` or another boundary folder, then reuse them in forms and server actions.

Do not rely on schema validation alone for business correctness. The entity or aggregate must still defend itself.
