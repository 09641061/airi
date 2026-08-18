# Mutations & Forms

## Mutations

Use Server Actions as framework adapters, not as domain.

```ts
'use server'

import { revalidateTag } from 'next/cache'
import { createProductSchema } from '@/contexts/product/interfaces/rest/schemas/create-product.schema'
import { createProductCommandService } from '@/contexts/product/application/internal/commandservices/factory'
import { createProductCommand } from '@/contexts/product/domain/model/commands/create-product.command'

export type CreateProductActionState =
  | { status: 'idle'; data: null; error: null }
  | { status: 'success'; data: { id: string }; error: null }
  | { status: 'error'; data: null; error: string }

export async function createProductAction(
  _prevState: CreateProductActionState,
  formData: FormData
) {
  const input = createProductSchema.parse({
    name: formData.get('name'),
    categoryId: formData.get('categoryId'),
  })
  const command = createProductCommand(input)

  try {
    const service = createProductCommandService()
    const productId = await service.handle(command)
    revalidateTag('products')
    return { status: 'success' as const, data: { id: productId.value }, error: null }
  } catch (error) {
    return {
      status: 'error' as const,
      data: null,
      error: error instanceof Error ? error.message : 'Unexpected error',
    }
  }
}
```

Rules:

1. Verify authentication and authorization inside every action.
2. Return a stable result shape.
3. Revalidate after successful mutations.
4. Keep the action small and framework-specific.
5. Transform schema input into a command before calling application services.

## Forms

Modern forms use React state hooks for mutation feedback.

```tsx
'use client'

import { useActionState } from 'react'
import { createProductAction } from '@/contexts/[context]/interfaces/actions/create-product.action'

type CreateProductActionState =
  | { status: 'idle'; data: null; error: null }
  | { status: 'success'; data: { id: string }; error: null }
  | { status: 'error'; data: null; error: string }

const initialState: CreateProductActionState = {
  status: 'idle',
  data: null,
  error: null,
}

export function CreateProductForm() {
  const [state, formAction, pending] = useActionState(
    createProductAction,
    initialState
  )

  return (
    <form action={formAction}>
      <input name="name" required />
      <input name="categoryId" required />
      <button disabled={pending} type="submit">
        Save
      </button>
  {state.status === 'error' ? <p>{state.error}</p> : null}
    </form>
  )
}
```

Use `useFormStatus` for nested pending UI and `useOptimistic` only when it improves UX.
Client Components should receive serializable view models only, never entities or aggregate instances.
