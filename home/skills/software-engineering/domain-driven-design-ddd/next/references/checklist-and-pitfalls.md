# Checklist & What To Avoid

## Checklist

Before merging a bounded context, verify:

1. Domain contains entities, aggregates, value objects, repositories, and services.
2. Application uses `internal/commandservices` and `internal/queryservices`.
3. Infrastructure is server-only.
4. Schemas validate input boundaries.
5. Domain still enforces business rules.
6. Server Actions are thin adapters.
7. Reads use `use cache` where appropriate.
8. Revalidation is intentional.
9. `app/` files stay thin.
10. No DTO or mapper classes were added.

## What To Avoid

1. `application/use-cases/` as a generic dumping ground.
2. `queries/` inside application when they belong to domain contracts.
3. Business rules living only in Zod schemas.
4. Server Components importing client-only modules.
5. Direct backend calls from Client Components.
6. Sentinel values like `0` for control flow.

This version is intentionally DDD-first and Next.js-native: domain contracts in domain, orchestration in application, IO in infrastructure, and routes in `app/`.
