# Infrastructure Layer and Composition

[Skill overview and workflow](../SKILL.md). Examples target Next.js 16 and React 19.3; verify project versions.

## Infrastructure Layer and Composition

Use native `fetch` as this project’s default. An alternative such as Axios needs a concrete capability that fetch does not adequately cover for the project (for example, required browser upload-progress integration); this is not a universal Axios prohibition.

Infrastructure contains real IO: native `fetch`, HTTP configuration, credentials, runtime response validation, and persistence adapters. Keep generated OpenAPI request/response types in `infrastructure/http/contracts/`; do not export them as application or domain models. Set timeouts, handle non-success statuses, and translate failures explicitly. For protected server requests, use an explicit uncached policy such as `fetch(url, { ...options, cache: 'no-store' })`, with controlled credentials and no conflicting cache options.

### Remote Writer

This is an **illustrative contract, not a claim about an existing Spring endpoint**: `POST /products` returns `{ id: string }`; 403 means forbidden; 422 with `{ code: "CATEGORY_NOT_AVAILABLE" }` means category rejection; other 409/422 responses mean product rejection. Align these mappings with the actual Spring API. An unknown non-success status is technical, not a fabricated business rule. The base URL and actor-scoped headers come from trusted server composition, never form input. The request ID is supplied by the request-scoped edge context described below. Composition allowlists credential headers and excludes any case variant of `X-Request-Id` from actorHeaders so there is exactly one correlation value.

```ts
// infrastructure/http/http-product-writer.ts
import 'server-only'
import type { ProductWriter } from '../../application/ports/product-writer'
import type { CreateProductCommand } from '../../application/commands/create-product.command'
import type { ProductId } from '../../application/models/product-id'
import { ApplicationError } from '../../application/errors/application-error'
import { TechnicalError } from '../../application/errors/technical-error'

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

export class HttpProductWriter implements ProductWriter {
  constructor(
    private readonly baseUrl: string,
    private readonly actorHeaders: Readonly<Record<string, string>>,
    private readonly requestId: string
  ) {}

  async create(command: CreateProductCommand): Promise<ProductId> {
    try {
      const response = await fetch(new URL('/products', this.baseUrl), {
        method: 'POST',
        headers: {
          ...this.actorHeaders,
          'Content-Type': 'application/json',
          'X-Request-Id': this.requestId,
        },
        body: JSON.stringify(command),
        cache: 'no-store',
        signal: AbortSignal.timeout(5000),
      })
      if (response.status === 403) throw new ApplicationError('FORBIDDEN')
      if (response.status === 409 || response.status === 422) {
        const rejection: unknown = await response.json().catch(() => null)
        throw new ApplicationError(
          response.status === 422 && isRecord(rejection) &&
          rejection.code === 'CATEGORY_NOT_AVAILABLE'
            ? 'CATEGORY_NOT_AVAILABLE'
            : 'PRODUCT_REJECTED'
        )
      }
      if (!response.ok) {
        throw new TechnicalError('UNAVAILABLE', {
          cause: new Error(`Unexpected Spring status ${response.status}`),
        })
      }
      let body: unknown
      try {
        body = await response.json()
      } catch (cause) {
        throw new TechnicalError('INVALID_RESPONSE', { cause })
      }
      if (!isRecord(body) || typeof body.id !== 'string' || !body.id.trim()) {
        throw new TechnicalError('INVALID_RESPONSE', {
          cause: new Error('Spring product response failed ID shape validation'),
        })
      }
      return body.id
    } catch (error) {
      if (error instanceof ApplicationError || error instanceof TechnicalError) {
        throw error
      }
      throw new TechnicalError('UNAVAILABLE', { cause: error })
    }
  }
}
```

This remote flow has no local Product entity, repository `save`, or client ID allocation. Runtime provider validation here uses type guards, not the form schema; generated transport types would still need runtime validation.

### Optional Query ACL (Not a Create Precheck)

Add these files only when a category-selection UI needs a query to explain whether a selected category is currently selectable:

```txt
application/ports/category-catalog.ts
infrastructure/acl/http-category-catalog.ts
```

```ts
// application/ports/category-catalog.ts (optional query consumer only)
export interface CategoryCatalog {
  exists(categoryId: string): Promise<boolean>
}
```

The consumer-owned ACL implements this port and translates provider identifiers/statuses into the query consumer’s availability semantics. A concrete use is showing “This category is no longer selectable” beside a saved selection before the user edits it. Wire it into that optional query, **not CreateProductService or the main composition below**. It adds UX feedback, not a mandatory command precheck or a consistency guarantee: Spring can still reject the later write. Distinguish absence from forbidden access, malformed responses, and provider unavailability. Never use a sentinel such as `0` as a fake identifier or fallback success. Keep translation beside the external adapter, not in Domain or a shared provider model.

### Composition at the Edge

`interfaces/server/composition.ts` is server-only. It creates `HttpProductWriter` and the product reader adapter, then injects them into `CreateProductService` and `ListProductsService`, respectively. Its `createProductServices(actor, requestContext)` factory returns `{ createProduct, listProducts }`. It constructs `new HttpProductWriter(baseUrl, actorHeaders, requestContext.requestId)` and `new CreateProductService(writer)`, with no category dependency. Every HTTP adapter, including the reader and any optional ACL, receives the same request-scoped ID and sends `X-Request-Id` to Spring. This is a project-defined factory, not a Next.js API. It must scope adapters to the verified actor/tenant and trusted backend credentials; never retain request credentials in a mutable global singleton. In tests, inject in-memory ports directly instead. Correlation stays in edge composition and HTTP adapters; do not add HTTP headers, framework types, or logging dependencies to Application commands or services.

Similarly, `interfaces/server/authorization.ts` exposes project-defined `requireActor()` and `authorizeProductCreation(actor)` helpers. They verify the server session and the actor's current permission in the selected tenant, rejecting unauthenticated or forbidden requests before composition. Reads need their own authorization policy. If access depends on a particular resource, enforce that check against authoritative data, not merely a role name or a client-supplied tenant ID. The backend must also authorize the operation. These helpers and adapters require implementation for the application's identity provider and API; their names below describe contracts, not built-in behavior.

### Request-Scoped Correlation

Generate an ID at the server edge by default; never read an arbitrary browser `X-Request-Id` into the context. If propagation is required, only pass an ID from an authenticated/trusted upstream whose ingress strips client-supplied values, and validate its format and length. Trusted upstream IDs must be opaque, non-secret, and free of PII. Syntax validation alone does not establish trust.

```ts
// interfaces/server/request-context.ts
import 'server-only'
import { randomUUID } from 'node:crypto'

export function createRequestContext(trustedUpstreamId?: string) {
  const requestId = trustedUpstreamId !== undefined &&
    trustedUpstreamId.length >= 1 && trustedUpstreamId.length <= 64 &&
    /^[A-Za-z0-9]/.test(trustedUpstreamId) &&
    !/[^A-Za-z0-9_-]/.test(trustedUpstreamId)
    ? trustedUpstreamId
    : randomUUID()
  return Object.freeze({ requestId })
}
```

The action below uses generation, not inbound headers. Create the context once per server operation and pass it explicitly to composition and logging; never store it in a mutable global. Reads, Route Handlers, and other mutations follow the same policy. Correlation is diagnostic only, never authentication, authorization, tenant identity, or an idempotency key.
