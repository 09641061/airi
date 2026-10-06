# Project Structure

Each bounded context follows the same layout. Start with the four canonical sub-packages and add more only when the context becomes large enough to need them.

## Canonical layout

```
internal/
  <context>/
    domain/
    application/
    infrastructure/
    interfaces/
```

Small context example:

```
internal/
  order/
    domain/
      order.go
      order_id.go
      money.go
      status.go
      repository.go        // port
      errors.go            // typed domain errors
    application/
      service.go           // use case orchestration
    infrastructure/
      postgres.go          // repository adapter
    interfaces/
      http.go              // net/http handlers
      resources.go         // request/response DTOs
```

## Layer responsibilities

| Layer | Allowed | Forbidden |
|-------|---------|-----------|
| `domain/` | Stdlib only, project's own domain packages | Any framework, driver, transport, or `infrastructure` import |
| `application/` | Stdlib, `domain/`, ACL facades, `infrastructure/` for ports that the application itself defines | HTTP types, JSON tags, ORM models |
| `infrastructure/` | Stdlib, drivers (`pgx`, `nats`), `domain/` ports, `application/` ACL facades | None — this is the outermost ring |
| `interfaces/` | Stdlib, `net/http`, OpenAPI, `application/`, `domain/` for result types | Direct database access, transport-agnostic business logic |

## Module path

Replace the literal `context-name` in every example with the real Go module path of the project, e.g. `github.com/acme/platform/order`. Imports look like:

```go
import (
    "github.com/acme/platform/order/domain/model/valueobjects"
    "github.com/acme/platform/order/domain/repositories"
    "github.com/acme/platform/order/application"
)
```

Never use `context-name/...` as a literal import path — it will not compile.

## When to split

- One context per directory under `internal/`. Two contexts do not share a Go package.
- If `domain/` exceeds ~15 files, group by `domain/model/aggregates/`, `domain/model/valueobjects/`, `domain/model/events/`, `domain/repositories/`, `domain/services/`.
- If `application/` exceeds ~10 use cases, group by `application/commands/`, `application/queries/`, `application/acl/`.
- `infrastructure/` and `interfaces/` are split by technology (`infrastructure/persistence/`, `infrastructure/messaging/`, `interfaces/rest/`, `interfaces/grpc/`).

## Checklist

- [ ] Context lives under `internal/<context>/`
- [ ] Four sub-packages exist: `domain/`, `application/`, `infrastructure/`, `interfaces/`
- [ ] Imports between layers respect the dependency rule
- [ ] No `internal/<context>/...` import appears inside another context's packages
