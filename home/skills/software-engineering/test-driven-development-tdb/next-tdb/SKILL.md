---
name: nextjs-ddd-testing
description: Write tests for a Next.js App Router application built with Domain-Driven Design — domain model, commands/queries, application services, infrastructure adapters, Client/Server Components, Server Actions, Route Handlers, integration and E2E flows. Use whenever asked to write, review, or scaffold tests (Vitest/React Testing Library/Playwright/MSW) for a Next.js codebase following DDD/hexagonal patterns.
---

# Next.js App Router Bounded Context Testing

Recommended stack: Vitest, React Testing Library, Playwright, jsdom, MSW, test database or database container for integration tests.

Tests must be **fast, isolated, repeatable, automated**, and **independent from production infrastructure**.

## Core conventions (apply to every layer)

- **Test structure** mirrors the app structure and the boundary being tested — unit/integration tests end with `.test.ts`/`.test.tsx`, Playwright tests end with `.spec.ts`. Colocate with the code or place under `tests/unit`, `tests/integration`, `tests/e2e`. Tests must not depend on execution order or shared mutable state; unit tests must not require a real database, server, or external service.
- **Naming:** `should [expected behavior] when [condition]` — e.g. `should return validation error when name is blank`. Avoid generic names like `test1` or `worksCorrectly`; names should read as documentation.
- **Organization:** every unit/integration test follows **Arrange / Act / Assert** — one main behavior under Act, no unrelated responsibilities in the same case.

## Build order

Follow this order — each step builds on the previous one. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Domain model — value objects, entities, aggregates, domain services, events | [references/domain-model.md](references/domain-model.md) |
| 2 | Commands & queries | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 3 | Application services & infrastructure (repositories/gateways) | [references/application-and-infrastructure.md](references/application-and-infrastructure.md) |
| 4 | Server Actions & Route Handlers | [references/server-actions-and-routes.md](references/server-actions-and-routes.md) |
| 5 | Client & Server Components | [references/components.md](references/components.md) |
| 6 | Integration & end-to-end flows (Playwright) | [references/integration-and-e2e.md](references/integration-and-e2e.md) |

Before writing tests for any layer, check [references/mocking-and-test-data.md](references/mocking-and-test-data.md): mock only dependencies outside the unit under test — never mock the class under test, and prefer MSW over mocking `fetch` directly.

Before shipping, check [references/coverage-ci-and-checklist.md](references/coverage-ci-and-checklist.md) for coverage expectations by layer, CI requirements, test execution commands, the recommended testing sequence, common pitfalls, and the final checklist.

## Source of truth

The original, unsplit guide (kept for traceability) lives at:
`software-engineering/test-driven-development-tdb/next/nextjs-ddd-testing.md`.
