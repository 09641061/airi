# Mutations and Forms

[Skill overview and workflow](../SKILL.md). Examples target Next.js 16 and React 19.3; verify project versions.

## Mutations

Server Actions are framework adapters, not business services. Treat every exported action as a remotely callable server entry point, even when the UI hides its button.

```ts
// interfaces/actions/create-product-action-state.ts
export type CreateProductActionState =
  | { status: 'idle'; error: null }
  | { status: 'error'; error: string }

// interfaces/actions/create-product.action.ts
'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { ApplicationError } from '../../application/errors/application-error'
import { createProductSchema } from '../schemas/create-product.schema'
import { recordSafely } from '../server/observability'
import { createRequestContext } from '../server/request-context'
import { createProductServices } from '../server/composition'
import { requireActor, authorizeProductCreation } from '../server/authorization'
import type { CreateProductActionState } from './create-product-action-state'

export async function createProductAction(
  _previous: CreateProductActionState,
  formData: FormData
): Promise<CreateProductActionState> {
  const requestContext = createRequestContext()
  const actor = await requireActor()
  await authorizeProductCreation(actor)

  const parsed = createProductSchema.safeParse({
    name: formData.get('name'),
    categoryId: formData.get('categoryId'),
  })
  if (!parsed.success) {
    return { status: 'error', error: 'Check the product name and category.' }
  }

  try {
    const { createProduct } = createProductServices(actor, requestContext)
    await createProduct.handle(parsed.data)
  } catch (error) {
    if (error instanceof ApplicationError) {
      return {
        status: 'error',
        error: error.code === 'CATEGORY_NOT_AVAILABLE'
          ? 'Choose an available category.'
          : 'The product could not be created with these values.',
      }
    }
    await recordSafely('product_write_unexpected', error, {
      ...requestContext, boundedContext: 'product', operation: 'createProduct',
    })
    return { status: 'error', error: 'Unable to confirm the result. Check your products before retrying.' }
  }

  try {
    revalidatePath('/products')
  } catch (error) {
    await recordSafely('product_cache_invalidation_failed', error, {
      ...requestContext, boundedContext: 'product', operation: 'invalidateProducts',
    })
  }
  redirect('/products')
}
```

Protected observability records the exception and its technical cause chain with **sanitized stacks**, operation, bounded context, and request ID, not just an event name. Both TechnicalError and unknown failures reach this logging path before a fixed client message is returned. Never return `error.message` to the client.

```ts
// interfaces/server/observability.ts
import 'server-only'
import { sanitizeError } from './diagnostic-policy'

type SafeEvent = 'product_write_unexpected' | 'product_cache_invalidation_failed'
type DiagnosticContext = Readonly<{
  requestId: string
  boundedContext: 'product'
  operation: 'createProduct' | 'invalidateProducts'
}>

export async function recordSafely(
  event: SafeEvent,
  error: unknown,
  context: DiagnosticContext
): Promise<void> {
  try {
    const diagnostic = sanitizeError(error)
    await console.error(JSON.stringify({ event, ...context, diagnostic }))
  } catch {
    // Redaction, serialization, and sink failures cannot change the outcome.
  }
}
```

`diagnostic-policy.ts` is a **project-defined server-only implementation contract**, not a Next.js API or a generic redaction guarantee. It exports `sanitizeError(error: unknown)`, returning a bounded, JSON-safe diagnostic with safe exception type/code, sanitized stack frames, and sanitized nested causes. Implement and test it against the deployed runtime/logger before adopting this snippet: allowlist diagnostic codes and owned module/function/line frame metadata, discard raw stack message lines, absolute/private paths, URL queries, and arbitrary exception properties. Retain safe call-site/line information and causal structure rather than reducing everything to an event label. Redact tokens, credentials, and PII in every retained field; never log raw request/response bodies, headers, or arbitrary messages. Handle cycles, non-Error values, throwing getters, and size/depth limits. Do not rely on a token regex alone. The sink must be restricted server-side with access and retention controls; browser console logging is not a substitute.

This example uses a synchronous console sink inside an async non-throwing helper. If replaced with an async project logger, **await its promise inside this try** to consume rejection as well as synchronous throws; configure a bounded sink timeout so telemetry does not block completion indefinitely. Extend the safe event/operation vocabulary for reads and other operations, using the same diagnostic policy. Authorization boundary failures need equivalent protected diagnostics without swallowing framework redirects. No raw error object is sent to the sink or client. A sanitizer/sink failure can lose telemetry but must never change the operation outcome.

A cache failure after a confirmed write still redirects; it neither returns a failed-write state nor invites a retry. Operational monitoring can reconcile stale reads. A transport failure can leave the write outcome uncertain; backend idempotency or reconciliation is needed before automatic retries.

Authentication/authorization failures are handled by the project's server boundary policy; never swallow a login redirect. Mutation failures return a serializable, stable state without raw exception messages. This example redirects on success, so no success state is needed. Keep `redirect` outside the business `try/catch` because it uses framework control flow. Revalidation failures must not be presented as if the write never happened.

Use invalidation matching the actual read policy. In Next.js 16, `updateTag(tag)` is for immediate expiration/read-your-own-writes in Server Actions, while `revalidateTag(tag, 'max')` uses stale-while-revalidate. Do not use the deprecated one-argument `revalidateTag` form. Public or tenant-scoped tags must match the edge read wrappers; neither tag invalidation nor `revalidatePath` replaces authorization.
## Forms

Forms manage interaction and mutation feedback; the Action validates input and passes the compatible command shape.

```tsx
// interfaces/components/create-product-form.tsx
'use client'

import { useActionState } from 'react'
import { createProductAction } from '../actions/create-product.action'
import type { CreateProductActionState } from '../actions/create-product-action-state'

const initialState: CreateProductActionState = { status: 'idle', error: null }

export function CreateProductForm() {
  const [state, formAction, pending] = useActionState(createProductAction, initialState)

  return (
    <form action={formAction}>
      <label htmlFor="product-name">Name</label>
      <input id="product-name" name="name" required maxLength={120} />
      <label htmlFor="category-id">Category</label>
      <input id="category-id" name="categoryId" required />
      <button disabled={pending} type="submit">Save</button>
      <p aria-live="polite">{state.status === 'error' ? state.error : null}</p>
    </form>
  )
}
```

Use `useFormStatus` for nested pending UI and `useOptimistic` only when it improves UX with a clear failure/reconciliation strategy. Client Components receive serializable view models (plain data, not entity instances); a Server Action reference is the framework-supported exception for behavior crossing this boundary. Importing an Action reference does not authorize importing its server dependencies into ordinary client modules.
