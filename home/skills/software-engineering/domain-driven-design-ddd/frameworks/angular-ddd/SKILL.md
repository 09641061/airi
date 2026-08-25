---
name: ddd-angular
description: Implement a complete Domain-Driven Design (DDD) bounded context in a standalone, signals-first Angular frontend — value objects, commands, queries, events, domain services, infrastructure gateways, application services, REST resource contracts, page orchestration, components/forms, and cross-context ACL. Use whenever asked to build, scaffold, or review a bounded context, feature module, page component, or CQRS layer in an Angular/TypeScript codebase following DDD patterns.
---

# DDD Bounded Context Implementation (Angular)

Baseline stack: Angular 19+, standalone components, `inject()`, Signals, zoneless change detection, built-in control flow syntax.

Naming principle is mandatory across the whole context: **Descriptive/Role-based Naming** or **Explicit Transformation Naming**.

For the language-agnostic modeling rules behind this skill — subdomains, bounded contexts, context mapping, building blocks, aggregate boundaries, object lifecycle, and CQRS adoption levels — see [ddd-core](../../ddd-core/SKILL.md).

## Core rules

1. Completely avoid creating DTO classes.
2. Completely avoid mapper classes.
3. Appropriately documented responses in Swagger/OpenAPI must be consumed as contract in frontend.
4. Do not use fake API in runtime flow; consume real API endpoints.
5. Components and providers are **standalone** by default (no `NgModule`).
6. Use the `inject()` function for dependency injection instead of constructor parameter injection — in services, guards, resolvers, and components alike.
7. Use the built-in control flow syntax (`@if`, `@for`, `@switch`) in templates; do not use the legacy `*ngIf`/`*ngFor` structural directives.
8. Prefer **Signals** for local/derived UI state (`signal`, `computed`, `effect`) over `BehaviorSubject`-based state; keep `Observable`s at the gateway/HTTP boundary and bridge with `toSignal`/`toObservable` when needed.
9. Target **zoneless change detection** (`provideZonelessChangeDetection()`) as the default for new bounded contexts; avoid relying on `Zone.js`-implicit change detection in new code.

## Build order

Follow this order — load each reference only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Value objects (IDs, validated primitives) | [references/value-objects.md](references/value-objects.md) |
| 2 | Enums/union types | — (plain TS union types, no reference needed) |
| 3 | Commands & Queries | [references/commands-and-queries.md](references/commands-and-queries.md) |
| 4 | Domain services (interfaces) | [references/domain-services.md](references/domain-services.md) |
| 5 | Entities/Aggregates | — (reuse shared frontend core folder for ID/audit fields when available) |
| 6 | Domain events | [references/events.md](references/events.md) |
| 7 | Infrastructure gateways (real API) | [references/infrastructure-gateways.md](references/infrastructure-gateways.md) |
| 8 | Command/Query service implementations | [references/application-services.md](references/application-services.md) |
| 9 | REST resources (frontend contracts) | [references/rest-resources.md](references/rest-resources.md) |
| 10 | Frontend controllers/pages (orchestration) | [references/pages-and-orchestration.md](references/pages-and-orchestration.md) |
| 11 | Components & forms | [references/components-and-forms.md](references/components-and-forms.md) |
| 12 | Transformers, guards/interceptors/routes | — (functional `CanActivateFn`/`HttpInterceptorFn`, lazy `loadComponent`/`loadChildren`) |

If the context needs to talk to another bounded context, add the **ACL layer** — see [references/acl-cross-context.md](references/acl-cross-context.md). Never let contexts call each other directly.

## Source of truth

The original, unsplit guide (kept for traceability) lives at:
`software-engineering/domain-driven-design-ddd/angular/angular-ddd.md`.
