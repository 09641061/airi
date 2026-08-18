# Reads

For reads in Next.js:

1. Server Components call query services directly.
2. Stream slow data with `loading.tsx` or `Suspense`.
3. Cache deterministic reads with `use cache`.

```ts
import { cacheLife, cacheTag } from 'next/cache'

export async function listProductsQueryService(): Promise<ProductSummary[]> {
  'use cache'
  cacheLife('hours')
  cacheTag('products')
  return productQueryRepository.list()
}
```

## Notes

1. Enable `cacheComponents: true` in `next.config.ts`.
2. Read `cookies()`, `headers()`, and `searchParams` outside cached scopes.
3. Use `cacheTag`, `updateTag`, `revalidateTag`, or `revalidatePath` intentionally.
4. `experimental.dynamicIO` and `experimental.useCache` are deprecated in favor of top-level `cacheComponents`.
