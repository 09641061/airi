# Infrastructure Layer

Infrastructure contains real IO.

## Gateways

Use gateways for HTTP communication.

```ts
import 'server-only'

export interface CategoryGateway {
  exists(categoryId: string): Promise<boolean>
}
```

## Repository Implementations

Repository implementations belong here, not in domain.

```txt
infrastructure/repositories/
```

Use `fetch` or another server-side client as needed.
Keep HTTP and persistence access behind gateways and repository implementations.
