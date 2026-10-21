# REST Resources and Gin Controllers

Gin is the HTTP adapter. Keep public HTTP shapes and transport concerns at the REST boundary, separate from domain models and application contracts.

## REST resources (DTOs)

Suggested location: `[context-name]/interfaces/rest/resources/`.

- Define request/response structs with `json` and, where appropriate, Gin binding tags in this boundary layer.
- Keep transport/input validation distinct from domain invariants. Binding validation cannot replace domain checks.
- Map explicitly between HTTP resources, application contracts, and results. Avoid reflection-based generic mappers unless a concrete need justifies one.
- Describe required/optional fields and success/error schemas in OpenAPI 3.1; keep public contracts stable as the domain evolves.

## Controllers

Suggested location: `[context-name]/interfaces/rest/controllers/`.

- Import Gin only in HTTP controllers (and applicable HTTP middleware/bootstrap).
- Bind and validate a request, create a Command or Query, invoke an application use case with `c.Request.Context()`, then map the result explicitly.
- Keep handlers small: no domain invariants, persistence access, or cross-context orchestration.
- Translate typed/application errors to the documented HTTP status and response without leaking sensitive internal details.
- Register routes at startup and document relevant success, validation, authorization, conflict, absence, and server-error responses in OpenAPI.

## HTTP tests and review

Use Gin with `net/http/httptest` to verify request parsing, validation, status/error translation, and cancellation propagation. Cover applicable success, invalid input, absence, conflict, and server-error paths. Do not require a real network server for controller contract tests.

**Checklist:** Gin stays at the HTTP boundary; DTOs do not pollute domain types; mappings are explicit; HTTP behavior matches the published contract.
