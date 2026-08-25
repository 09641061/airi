---
name: ddd-nextjs
description: Implement a Domain-Driven Design (DDD) bounded context in a Next.js App Router frontend with TypeScript — domain model, application/CQRS services, infrastructure gateways, Server Components/Actions, Cache Components, forms, and route orchestration. Use whenever asked to build, scaffold, or review a bounded context, feature module, Server Action, or data-fetching layer in a Next.js/TypeScript codebase following DDD patterns.
---

# DDD Bounded Context Implementation (Next.js App Router + TypeScript)

Keeps the domain pure, the application layer explicit, and the UI thin.

For the language-agnostic modeling rules behind this skill — subdomains, bounded contexts, context mapping, building blocks, aggregate boundaries, object lifecycle, and CQRS adoption levels — see [ddd-core](../../ddd-core/SKILL.md).

## Core rules

1. Prefer **Server Components** by default.
2. Use **Client Components** only for browser interaction.
3. Use **Server Actions** for mutations.
4. Use **Cache Components** and `use cache` for deterministic reads.
5. Avoid DTO classes and mapper classes.
6. Use `type` / `interface`, pure functions, and explicit transforms.
7. Protect server-only modules with `import 'server-only'`.
8. Validate input with **Zod** or similar schemas.
9. Keep domain rules inside the domain, not in schemas.
10. Keep App Router files thin and route-focused.
11. With `cacheComponents: true`, data fetching is dynamic by default and static output is opt-in via `use cache` or `Suspense`.
12. Cache Components also enables Partial Prerendering (PPR) for the App Router.

## Recommended structure

Keep the bounded context outside `app/`, and let `app/` only orchestrate routes.

```txt
src/
  app/
    [context]/
      page.tsx
      loading.tsx
      error.tsx
      not-found.tsx

  contexts/
    [context]/
      domain/
      application/
      infrastructure/
      interfaces/
        actions/
```

- `domain` has no React or Next.js imports.
- `application` orchestrates domain and infrastructure.
- `infrastructure` is server-only by default.
- `interfaces` contains UI-facing adapters and transforms.

## Build order

Follow this order — load each reference only when you reach that step.

| # | Step | Reference |
|---|------|-----------|
| 1 | Domain model (value objects, entities, aggregates, commands, queries, events, repositories, domain services) | [references/domain-model.md](references/domain-model.md) |
| 2 | Validation strategy (schemas vs domain invariants) | [references/validation-strategy.md](references/validation-strategy.md) |
| 3 | Application layer (command/query services, outbound services, ACL) | [references/application-layer.md](references/application-layer.md) |
| 4 | Infrastructure layer (gateways, repository implementations) | [references/infrastructure-layer.md](references/infrastructure-layer.md) |
| 5 | Reads (Server Components, `use cache`, streaming) | [references/reads.md](references/reads.md) |
| 6 | Mutations & forms (Server Actions, `useActionState`) | [references/mutations-and-forms.md](references/mutations-and-forms.md) |
| 7 | Route orchestration (`app/` files, Route Handlers, Proxy) | [references/route-orchestration.md](references/route-orchestration.md) |
| 8 | UI layer (`interfaces/`) | [references/ui-layer.md](references/ui-layer.md) |

Before shipping, check [references/checklist-and-pitfalls.md](references/checklist-and-pitfalls.md).

## Source of truth

The original, unsplit guide (kept for traceability) lives at:
`software-engineering/domain-driven-design-ddd/next/nextjs-ddd.md`.
