# Application Layer

Use the application layer to orchestrate domain objects and external dependencies.

## Command Services

Place implementations in:

```txt
application/internal/commandservices/
```

Example:

```ts
export class CreateProductCommandServiceImpl implements ProductCommandService {
  constructor(
    private readonly products: ProductRepository,
    private readonly categoryGateway: CategoryGateway
  ) {}

  async handle(command: CreateProductCommand): Promise<ProductId> {
    const categoryExists = await this.categoryGateway.exists(command.categoryId)
    if (!categoryExists) throw new Error('Invalid category')

    const productId = await this.products.nextId()
    const product = Product.create(productId, command.name)
    await this.products.save(product)
    return product.id
  }
}
```

## Query Services

Place implementations in:

```txt
application/internal/queryservices/
```

Queries should be read-only and optimized for UI consumption.

Return serializable read models or view models from the application layer.

## Outbound Services

Use outbound services when application code needs another bounded context.

```txt
application/internal/outboundservices/
```

## ACL

Use ACLs to translate foreign models into consumer-friendly domain types.

Rules:

1. Keep the interface small.
2. Map external concepts explicitly.
3. Do not leak provider models into the consumer domain.
4. Prefer `null` or typed errors over sentinel values like `0`.
