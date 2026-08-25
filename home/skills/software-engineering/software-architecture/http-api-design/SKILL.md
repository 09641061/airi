---
name: http-api-design
description: Design high-quality HTTP APIs and RESTful contracts — method semantics, canonical status codes, RFC 7807 / RFC 9457 Problem Details error schemas, clean resource URIs, filtering, sorting, keyset/cursor pagination, ETag and If-Match optimistic concurrency, Cache-Control, idempotency keys, backward-compatible evolvability, and OpenAPI 3.1 contracts. Use when defining endpoints, choosing HTTP methods, standardizing error formats, implementing concurrency or pagination, designing idempotency keys, or versioning APIs.
---

# HTTP API & RESTful Service Design

Baseline stack: HTTP/1.1 & HTTP/2/3, JSON, OpenAPI 3.1, RFC 7807 / RFC 9457 Problem Details.

Naming principle is mandatory across the whole API surface: **Noun-based Resource Modeling** with lowercase `kebab-case` URI path segments.

For the underlying domain modeling rules feeding into API resources — subdomains, bounded contexts, and aggregate boundaries — see [ddd-core](../../domain-driven-design-ddd/ddd-core/SKILL.md).

## Core rules

1. **Noun-based URI resources**: URIs identify **nouns** (resources and collections); HTTP methods express the action. Never use verbs in URIs for standard operations (`GET /orders`, not `GET /getOrders`). Genuine non-CRUD operations are modeled as sub-resources (`POST /orders/{id}/cancellation`).
2. **Exact HTTP verb semantics**: Strictly respect RFC 9110 safety (`GET`, `HEAD`) and idempotency (`GET`, `HEAD`, `PUT`, `DELETE`). `PUT` completely replaces the target resource; `PATCH` performs partial updates using standard media types (`application/merge-patch+json` [RFC 7386] or `application/json-patch+json` [RFC 6902]).
3. **Canonical status codes**: Never return `200 OK` with an error in the body. Return `201 Created` with a `Location` header for creations, `204 No Content` for payloadless mutations/deletions, `400` for syntactic invalidity, `422` for semantic validation errors, `401` for missing/invalid authentication, `403` for insufficient permissions, `409` for state conflicts, and `412` for precondition failures.
4. **Deterministic error schemas (RFC 7807 / RFC 9457)**: All 4xx and 5xx responses must use `application/problem+json` with a stable, resolvable `type` URI, descriptive `title`, `status`, `detail`, `instance`, and structured `invalid-params` validation arrays.
5. **Idempotency keys on critical creations**: Support the `Idempotency-Key: <UUID>` header on non-idempotent mutations (`POST`) such as payments and order submissions to prevent duplicate execution upon client retries.
6. **Optimistic concurrency & caching (ETag / If-Match / Cache-Control)**: Every mutable resource must expose an `ETag` header. Mutations (`PUT`, `PATCH`, `DELETE`) must validate `If-Match` to prevent the lost-update problem (`412 Precondition Failed` on mismatch). Declare `Cache-Control` explicitly on every response, including non-cacheable endpoints (`private, no-cache, no-store, must-revalidate`).
7. **Keyset / cursor pagination**: Enforce pagination on every collection endpoint with default and maximum limits (`limit=50`, `max=100`). Prefer cursor/keyset pagination (`?cursor=...`) over offset-based pagination (`?page=...`) for large, continuous, or rapidly mutating datasets.
8. **Backward-compatible evolution & versioning**: Prefer additive, non-breaking contract changes (optional request fields, new endpoints, new response attributes). When breaking changes are unavoidable, bump the major version in the URI path (`/v1/`, `/v2/`) and provide deprecation headers (`Deprecation`, `Sunset`) during an announced transition window.
9. **API-First OpenAPI 3.1 contract**: Define and lint (e.g., Spectral) the OpenAPI 3.1 specification before server implementation. The contract serves as the single source of truth across consumer teams.

## Build order

Follow this order — each step builds on the previous one. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Architecture & Resource Modeling (ROA, Constraints, Maturity) | [references/design-procedure.md](references/design-procedure.md) |
| 2 | URI Topology, Filtering & Keyset Pagination | [references/uris-and-collections.md](references/uris-and-collections.md) |
| 3 | HTTP Verb Semantics, Safety & Idempotency Keys | [references/method-semantics.md](references/method-semantics.md) |
| 4 | Canonical Status Codes & RFC 7807 / 9457 Problem Details | [references/status-codes-and-errors.md](references/status-codes-and-errors.md) |
| 5 | Cache-Control, ETag & If-Match Optimistic Concurrency | [references/caching-and-concurrency.md](references/caching-and-concurrency.md) |
| 6 | Backward-Compatible Evolution, Versioning & Sunset | [references/versioning.md](references/versioning.md) |
| 7 | Full Worked Example & OpenAPI 3.1 Contract Specification | [references/worked-example.md](references/worked-example.md) |
| 8 | Anti-Patterns Review & Pre-Production Certification Checklist | [references/antipatterns-and-checklist.md](references/antipatterns-and-checklist.md) |

Before shipping, verify all endpoints against the pre-production checklist in [references/antipatterns-and-checklist.md](references/antipatterns-and-checklist.md).
