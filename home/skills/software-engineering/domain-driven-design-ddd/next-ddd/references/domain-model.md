# Domain Model

## Value Objects

Value objects are immutable and validate their own invariants.

```ts
export type ProductId = Readonly<{ value: string }>

export function createProductId(value: string): ProductId {
  if (!value.trim()) throw new Error('ProductId is required')
  return Object.freeze({ value })
}
```

## Entities

Entities have identity and behavior.

```ts
export class Product {
  private constructor(
    public readonly id: ProductId,
    private name: string
  ) {}

  static create(id: ProductId, name: string) {
    if (!name.trim()) throw new Error('Name is required')
    return new Product(id, name)
  }

  rename(newName: string) {
    if (!newName.trim()) throw new Error('Name is required')
    this.name = newName
  }
}
```

## Aggregates

Aggregates protect consistency boundaries.

```ts
export class Order {
  private constructor(
    public readonly id: OrderId,
    private items: OrderItem[]
  ) {}

  addItem(item: OrderItem) {
    if (this.items.some((x) => x.productId.value === item.productId.value)) {
      throw new Error('Duplicate product in order')
    }
    this.items = [...this.items, item]
  }
}
```

## Commands

Commands represent write intent.

```ts
export type CreateProductCommand = {
  name: string
  categoryId: string
}
```

## Queries

Queries represent read intent.

```ts
export type ListProductsQuery = {
  search?: string
  page?: number
  pageSize?: number
}
```

## Events

Events capture facts that already happened.

```ts
export type ProductCreatedEvent = Readonly<{
  productId: string
  occurredOn: string
}>
```

## Repositories

Repository contracts belong to the domain.

```ts
export interface ProductRepository {
  save(product: Product): Promise<void>
  findById(id: ProductId): Promise<Product | null>
  nextId(): Promise<ProductId>
}
```

## Domain Services

Pure domain services hold domain logic that does not belong to a single entity or value object.

```ts
export interface ProductPricingPolicy {
  calculate(basePrice: number, categoryId: string): number
}
```

## Application CQRS Contracts

Command/query service contracts belong to the application layer, even if they are defined alongside domain types for convenience.

```ts
export interface ProductCommandService {
  handle(command: CreateProductCommand): Promise<ProductId>
}

export interface ProductQueryService {
  handle(query: ListProductsQuery): Promise<ProductSummary[]>
}
```
