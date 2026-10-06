# OpenAPI and Swagger

Every public HTTP API must be documented in OpenAPI 3.1. The contract is the source of truth for clients and for the test suite.

## Layout

```
api/
  openapi.yaml          # main contract
  paths/                # split by resource (optional, for large APIs)
  components/
    schemas/            # reusable types
    responses/          # RFC 7807 Problem Details
    parameters/
```

Or keep one big `openapi.yaml` at the root if the surface is small.

## Documentation per endpoint

- `@Summary`, `@Description`, `@Tags`, `@Accept`, `@Produce` for the operation.
- `@Param` for every parameter (path, query, body) with a type and example.
- `@Success` and `@Failure` for **every documented status code**, including:
  - `400` Bad Request (validation failures)
  - `401` Unauthorized (missing/invalid auth)
  - `403` Forbidden (insufficient permissions)
  - `404` Not Found
  - `409` Conflict
  - `422` Unprocessable Entity (semantic validation failure)
  - `500` Internal Server Error
- `@Router` for the path and method.

The problem-details response type is `application/problem+json`. Reference a reusable component instead of redefining it on every operation.

## Generating the OpenAPI file

Two reasonable workflows:

1. **Hand-write `openapi.yaml`** — full control, no tool lock-in. Recommended for small/medium surfaces.
2. **Generate from code annotations** — e.g. [`swaggo/swag`](https://github.com/swaggo/swag) with `// @...` comments, or [`ogen`](https://github.com/ogen-go/ogen) for code generation. Useful when you want a single source of truth in Go.

Pick one. Don't mix hand-written and generated specs in the same project.

## Serving Swagger UI

- **Production**: serve the OpenAPI YAML/JSON and Swagger UI from a static path on the API server, gated behind auth in non-public deployments.
- **Development**: serve at `/docs` or `/swagger`. Mount via `http.FileServer` on a subdirectory of the API binary, or as a separate container.

```go
// File: internal/<context>/interfaces/rest/server.go
package rest

import "net/http"

func MountDocs(mux *http.ServeMux, specBytes []byte) {
    mux.HandleFunc("GET /openapi.yaml", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/yaml")
        _, _ = w.Write(specBytes)
    })

    fs := http.FileServer(http.Dir("internal/<context>/interfaces/rest/docs"))
    mux.Handle("GET /docs/", http.StripPrefix("/docs/", fs))
}
```

Open `http://localhost:8080/docs/` for Swagger UI, `http://localhost:8080/openapi.yaml` for the raw spec.

## Checklist

- [ ] `openapi/openapi.yaml` exists and is the canonical HTTP contract
- [ ] Every public endpoint is documented (summary, params, success and failure responses)
- [ ] 401 / 403 / 500 responses are documented (not just 201 / 400 / 409)
- [ ] Problem Details is referenced as a reusable component
- [ ] Swagger UI is reachable at `/docs` in development
- [ ] The OpenAPI spec is consumed by client generators or contract tests, not just humans
