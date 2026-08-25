# Step 8 — Anti-patterns & pre-production certification checklist

## HTTP API Anti-patterns

### 1. RPC Over HTTP (Verbs in URIs)
* **Defect**: Endpoints like `POST /api/createCustomer`, `POST /api/deleteOrder?id=12`, `GET /api/getAllUsers`.
* **Fix**: Map actions onto semantic HTTP methods over noun collections: `POST /v1/customers`, `DELETE /v1/orders/12`, `GET /v1/users`.

### 2. HTTP 200 Tunneling (Errors in OK Payloads)
* **Defect**: Returning `200 OK` with `{ "success": false, "errorCode": 500, "message": "Database error" }`.
* **Fix**: Return canonical HTTP status codes (`400`, `404`, `422`, `500`). Gateways, service meshes, load balancers, and circuit breakers rely on the HTTP status line for alerting and health monitoring.

### 3. POST Overuse (The Single-Verb Anti-pattern)
* **Defect**: Routing all queries and mutations through `POST`, disabling HTTP caching proxies and violating idempotency guarantees.
* **Fix**: Use `GET` for safe reads, `PUT` for complete replacement, `PATCH` for partial delta updates, `DELETE` for removal, and `POST` for creations and execution sub-resources.

### 4. False Statelessness (In-Memory Session Leaks)
* **Defect**: Storing authentication sessions or workflow state in local web server memory (`HttpSession`), preventing seamless horizontal autoscaling.
* **Fix**: Use stateless cryptographic bearer tokens (`Authorization: Bearer <JWT>`) or persist distributed workflow state in the database.

### 5. Chatty APIs (Excessive Micro-Granularity)
* **Defect**: Forcing client applications to execute dozens of sequential HTTP calls to render a single view (e.g. separate calls for order header, line items, product names, customer address).
* **Fix**: Design composite aggregate resources, allow controlled query inclusions (`?include=items,shippingAddress`), or implement a Backend-for-Frontend (BFF).

### 6. Unbounded Collections
* **Defect**: `GET /orders` returning the entire table without pagination, which eventually causes out-of-memory errors in production.
* **Fix**: Enforce pagination with default and maximum limits on every collection endpoint (`limit=50`, `max=100`).

### 7. Bespoke Error Formats
* **Defect**: Heterogeneous error structures across endpoints without machine-readable error classification codes.
* **Fix**: Implement RFC 7807 / RFC 9457 `application/problem+json` with a stable, resolvable `type` URI.

---

## Pre-Production Certification Checklist

Before certifying an API service for production, verify compliance with each requirement:

- [ ] **URI Taxonomy**: All URIs identify lowercase plural nouns in `kebab-case` nested at most 2 levels deep.
- [ ] **Method Semantics**: `GET` and `HEAD` are strictly safe (zero side effects). `PUT` and `DELETE` are genuinely idempotent.
- [ ] **Partial Updates**: `PATCH` endpoints enforce standard media types (`application/merge-patch+json` or `application/json-patch+json`).
- [ ] **Idempotency Keys**: Non-idempotent creations (`POST`) supporting retries accept `Idempotency-Key: <UUID>` and enforce deduplication.
- [ ] **Stateless Authentication**: Server holds no in-memory sessions; authentication is managed via `Authorization: Bearer <token>`.
- [ ] **Canonical Status Codes**: Creations return `201 Created` with a `Location` header; payloadless mutations return `204 No Content`; errors return appropriate 4xx/5xx codes.
- [ ] **RFC 9457 Problem Details**: All error responses return `application/problem+json` with a stable `type` URI and structured `invalid-params` array.
- [ ] **Concurrency & Caching**: Mutable resources expose `ETag` and validate `If-Match`; all endpoints define explicit `Cache-Control` directives.
- [ ] **Pagination Enforced**: Every collection endpoint enforces default and maximum limits and supports cursor/keyset pagination for large datasets.
- [ ] **OpenAPI 3.1 Synchronized**: A complete, linted OpenAPI 3.1 specification exists and is kept in sync with code in CI pipelines.
