# Architecture and Structure

[Skill overview and workflow](../SKILL.md). Examples target Next.js 16 and React 19.3; verify project versions.

## Core Rules

Choose the model before choosing folders:

- **RICH CLIENT DOMAIN**: Domain / Application / Infrastructure / Interfaces, only when real local business behavior and invariants justify a frontend domain model.
- **REMOTE FEATURE**: Application / Infrastructure / Interfaces; Domain is optional, not a required empty layer. Remote orchestration is not an aggregate just because it creates a product.

For **Takodu**, Next.js is the frontend/BFF and Spring owns the authoritative domain, persistence, and ID generation. The main example below is a REMOTE FEATURE. Do not duplicate Spring aggregates in TypeScript just to satisfy a template. Never create layers, entities, repositories, events, value objects, ports, or transforms without a real responsibility, rule, boundary, or variation.

1. Prefer **Server Components** by default; use Client Components for browser interaction and React client behavior.
2. Keep `app/` as a routing shell and put bounded-context code outside it.
3. Put commands, queries, and their handlers in **Application**. Domain services express business rules, not CQRS contracts.
4. Application depends on consumer-owned ports and, when present, local Domain behavior, never concrete adapters.
5. Keep HTTP, native `fetch`, persistence, and OpenAPI transport contracts in **Infrastructure**.
6. Compose adapters and application services at the server edge, outside Application.
7. Use Server Actions for app-owned mutations and Route Handlers only where an HTTP boundary is needed.
8. Keep authentication, boundary validation, framework caching, revalidation, and redirects at the edge. Enforce authorization on the server for every protected operation.
9. Use Zod in Interfaces; an optional local Domain independently protects its invariants. Spring enforces authoritative rules for remote features.
10. Prefer `type` / `interface` and pure transform functions over ceremonial DTO or mapper classes.
11. Protect server adapters and composition modules with `import 'server-only'`; do not couple the framework-independent Domain or Application to this marker.
12. Never share protected data through a cache without a deliberate identity, authorization, and invalidation policy.
## Recommended Structure

The product context illustrates the convention. Add files only when the corresponding responsibility exists.

```txt
src/
  app/
    products/
      page.tsx
      loading.tsx
      error.tsx
      not-found.tsx
  contexts/
    product/
      application/
        commands/
          create-product.command.ts
        queries/
          list-products.query.ts
        models/
          product-summary.ts
          product-id.ts
        ports/
          product-reader.ts
          product-writer.ts
        errors/
          application-error.ts
          technical-error.ts
        internal/
          commandservices/
            create-product.service.ts
          queryservices/
            list-products.service.ts
      infrastructure/
        http/
          contracts/                 # Generated/validated OpenAPI transport types
          http-product-writer.ts
        queries/
          http-product-reader.ts
      interfaces/
        schemas/
          create-product.schema.ts
        actions/
          create-product.action.ts
          create-product-action-state.ts
        components/
          create-product-form.tsx
        server/
          composition.ts
          authorization.ts
          reads.ts
          observability.ts
          request-context.ts
          diagnostic-policy.ts       # Project-specific safe diagnostic serializer
```

Rules:

1. Domain has no React, Next.js, Zod, or transport imports.
2. **Application must not import Infrastructure, Next.js, or React**. It orchestrates use cases through injected ports and uses local Domain only when justified.
3. Infrastructure implements those ports and may depend inward on Application and Domain, never the reverse.
4. Interfaces adapts input/output. Its server composition root is the deliberate place that imports concrete Infrastructure and wires it to Application.
5. Consumer-owned outbound ports belong in `application/ports/`. Domain repositories may live in Domain when they model aggregate persistence in domain language. Read projections and external lookup contracts do not become domain repositories merely because they access data.
6. Browser-safe types and components must not transitively import server adapters. Avoid barrel exports that erase this boundary.
