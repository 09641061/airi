---
name: ddd-nextjs
description: Build or review DDD-oriented Next.js App Router frontend/BFF features with TypeScript. Distinguish remote features owned by a backend from justified rich client domains; implement application commands/queries, consumer-owned ports, HTTP adapters, Server Components/Actions, validation, safe caching, correlation, and protected observability. Use for Next.js feature modules, bounded contexts, Server Actions, and data-fetching architecture without imposing a domain model on every CRUD.
---

# DDD-Oriented Architecture for Next.js Frontend/BFF

Keep business ownership explicit, dependencies inward, and UI thin. These conventions are architectural choices, not universal DDD axioms.

Examples target **Next.js 16 and React 19.3**. Check project versions before using version-specific APIs; keep `react` and `react-dom` aligned. Snippets illustrate boundaries, not a complete runnable application. Project-specific authorization, composition, and diagnostic-policy helpers must be implemented and tested.

## Choose the model first

- **REMOTE FEATURE**: Application / Infrastructure / Interfaces. The backend owns authoritative business rules, transactions, persistence, and generated IDs. Domain is optional. This is the normal example for Takodu, where Next.js is frontend/BFF and Spring owns the backend domain; verify ownership in other projects.
- **RICH CLIENT DOMAIN**: add Domain only for actual local business behavior and invariants. Do not duplicate backend aggregates in TypeScript just to fill folders.

Never create layers, entities, repositories, events, value objects, ports, or transforms without a real responsibility, rule, boundary, or variation. Optional modeling background: [ddd-core](../../ddd-core/SKILL.md); it does not make a frontend Domain mandatory.

## Core rules

1. Commands, queries, and handlers belong in Application. Domain services express business policies, not CQRS interfaces.
2. Application depends on consumer-owned ports and optional local Domain, never Infrastructure, React, Next.js, or OpenAPI transport models. Infrastructure implements inward-owned ports; server-edge composition wires dependencies.
3. Use `ProductWriter.create(command)` for remote creation. Let Spring generate IDs and enforce category availability. Do not impose repository `nextId()`/`save()` or preliminary category lookups on remote commands. Optional query ACLs need concrete UX/business value and do not ensure write consistency.
4. Infrastructure owns HTTP, credentials, timeouts, runtime response validation, and transport translation. Native `fetch` is the project default; alternatives need a concrete unmet capability.
5. Zod input schemas live at the Interfaces boundary. Backend rules remain authoritative; optional local Domain protects its own invariants without Zod. Generate runtime-capable contract schemas or test manually repeated constraints against OpenAPI.
6. Distinguish local BusinessError, ApplicationError, and application-owned TechnicalError. Translate backend rejections and preserve technical causes for protected diagnostics; never return raw exception messages to browsers.
7. Prefer Server Components; keep `app/` thin and fetch through composed queries without loopback HTTP. Use Client Components where browser interaction begins; presentation receives serializable data, not entities or services.
8. Server Actions are app-owned mutation adapters: authenticate, authorize, validate, invoke Application, map errors, then invalidate/redirect. Route Handlers are for genuine HTTP boundaries. Proxy/layout checks never replace per-operation authorization.
9. Keep framework caching at the edge. Protected reads are uncached by default. Determinism alone does not justify shared caching; require identity/tenant/permission policies. `Suspense` streams, not caches. Cache Components is opt-in.
10. Separate confirmed write success from invalidation failure. Logging must not change outcomes; keep redirect outside catches. Uncertain transport outcomes require reconciliation/idempotency before retries.
11. Generate request IDs server-side or accept only validated trusted-upstream IDs. Propagate request-scoped correlation through adapters and protected diagnostics, never use it for authorization or idempotency. Sanitize stacks/causes and redact tokens/PII; never log raw bodies/headers.
12. Mark server adapters/composition with `server-only`, not framework-independent Domain/Application. Never leak actor credentials through global singletons or browser imports.
13. Keep React state minimal, derive values without synchronizing effects, use URL state when appropriate, and extract by responsibility. Use pure transforms only for real semantic translation; avoid copy-only factories, mapper ceremony, and flag-driven megaforms.

## Workflow and references

Load the relevant reference before implementing its boundary. References are self-contained extracts of the corrected guide and retain its illustrative contracts.

| Step | Task | Reference |
|---|---|---|
| 1 | Decide ownership and inspect the remote-first tree; skip local Domain unless justified | [Architecture and structure](references/architecture-and-structure.md) |
| 2 | Define commands, queries, ports, results, and error vocabulary | [Application layer](references/application-layer.md) |
| 3 | Only for real local behavior: model invariants and aggregate boundaries | [Optional domain model](references/domain-model.md) |
| 4 | Validate boundaries and prevent API-constraint drift | [Validation strategy](references/validation-strategy.md) |
| 5 | Implement adapters, optional ACL, composition, and request correlation | [Infrastructure layer](references/infrastructure-layer.md) |
| 6 | Compose authorized reads, streaming, and deliberate caching | [Reads](references/reads.md) |
| 7 | Implement authorized mutations, protected diagnostics, invalidation, and forms | [Mutations and forms](references/mutations-and-forms.md) |
| 8 | Keep routing/HTTP entry points thin | [Route orchestration](references/route-orchestration.md) |
| 9 | Review state, presentation, reuse, and pragmatic SOLID | [UI layer](references/ui-layer.md) |

Before completing work, apply [the checklist and pitfalls](references/checklist-and-pitfalls.md). Report actual validation and remaining project contracts; do not claim snippets compile or run without checking.

## Source and maintenance

Adapted from the corrected personal-notes guide:
`software-engineering/domain-driven-design-ddd/next/nextjs-ddd.md` in the separate `personal-notes` repository (not a path inside Airi).

The bundled references are usable without that checkout. When synchronizing, update this entry point and all affected references together; do not restore mandatory local aggregates, Application-to-Infrastructure imports, blanket caching, or command prechecks from older versions. Preserve `name: ddd-nextjs` for existing skill consumers.
