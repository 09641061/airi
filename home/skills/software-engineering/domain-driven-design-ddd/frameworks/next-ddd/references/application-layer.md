# Application Layer

[Skill overview and workflow](../SKILL.md). Examples target Next.js 16 and React 19.3; verify project versions.

## Application Layer

### Commands and Queries

Commands represent write intent and queries represent read intent. Both belong in Application, not under the domain model.

```ts
// application/commands/create-product.command.ts
export type CreateProductCommand = Readonly<{
  name: string
  categoryId: string
}>

// application/queries/list-products.query.ts
export type ListProductsQuery = Readonly<{
  search?: string
  page: number
  pageSize: number
}>

// application/models/product-summary.ts
export type ProductSummary = Readonly<{ id: string; name: string }>
```

The remote result type belongs to Application, not an artificial Domain value object:

```ts
// application/models/product-id.ts
export type ProductId = string
```

Pass validated `parsed.data` directly to the handler when it is structurally compatible with `CreateProductCommand`. No copy-only factory or transform is needed. Introduce a pure transform only for real translation, such as different names, units, or semantics across a boundary.

### Consumer-Owned Ports

```ts
// application/ports/product-writer.ts
import type { CreateProductCommand } from '../commands/create-product.command'
import type { ProductId } from '../models/product-id'

export interface ProductWriter {
  create(command: CreateProductCommand): Promise<ProductId>
}

// application/ports/product-reader.ts
import type { ListProductsQuery } from '../queries/list-products.query'
import type { ProductSummary } from '../models/product-summary'

export interface ProductReader {
  list(query: ListProductsQuery): Promise<readonly ProductSummary[]>
}
```

Keep ports cohesive (ISP): a category lookup consumer should not depend on an entire remote catalog SDK. Add only operations required by the consumer. Use adapter injection for provider variation, not a central `switch` on provider names inside application services.

### Command Services

```ts
// application/internal/commandservices/create-product.service.ts
import type { ProductId } from '../../models/product-id'
import type { ProductWriter } from '../../ports/product-writer'
import type { CreateProductCommand } from '../../commands/create-product.command'

export class CreateProductService {
  constructor(private readonly writer: ProductWriter) {}

  async handle(command: CreateProductCommand): Promise<ProductId> {
    return this.writer.create(command)
  }
}
```

The normal remote flow is **CreateProductService → ProductWriter.create → Spring**: no preliminary category lookup. The writer forwards the full command, including categoryId. Spring authorizes the operation, validates category availability and all authoritative invariants, persists the product, and generates the returned ID. The adapter translates its documented business rejection into ApplicationError.

### Query Services

```ts
// application/internal/queryservices/list-products.service.ts
import type { ListProductsQuery } from '../../queries/list-products.query'
import type { ProductReader } from '../../ports/product-reader'

export class ListProductsService {
  constructor(private readonly products: ProductReader) {}

  handle(query: ListProductsQuery) {
    return this.products.list(query)
  }
}
```

Queries are read-only and can return serializable application read models. Use an Interfaces view model only when the UI needs a different semantic shape; do not duplicate identical types at every layer. CQRS does not require separate service interfaces when the concrete handler already provides the needed API.

### Three Error Families

- **Domain BusinessError**: optional local invariant violations; not used by this remote flow.
- **Application ApplicationError**: use-case eligibility failures and translated backend business/authorization rejections.
- **Application-owned TechnicalError**: infrastructure translates network, protocol, and malformed-response failures into this vocabulary.

```ts
// application/errors/application-error.ts
export class ApplicationError extends Error {
  constructor(
    public readonly code: 'CATEGORY_NOT_AVAILABLE' | 'PRODUCT_REJECTED' | 'FORBIDDEN'
  ) {
    super(code)
    this.name = 'ApplicationError'
  }
}
```

```ts
// application/errors/technical-error.ts
export class TechnicalError extends Error {
  constructor(
    public readonly code: 'UNAVAILABLE' | 'INVALID_RESPONSE',
    options?: ErrorOptions
  ) {
    super(code, options)
    this.name = 'TechnicalError'
  }
}
```

Adapters translate network/protocol failures into this application-owned vocabulary and backend rejections into ApplicationError using documented status/code mappings, never raw `error.message`. Absence is `null` or `false` only when the port defines it that way; a timeout is not “category missing.” Preserve technical causes with `Error.cause` (an ES2022 runtime/library assumption here) until the server edge records sanitized diagnostics. These error objects and their causes are server-internal, never serialized to clients. Do not attach raw bodies or headers as causes.
