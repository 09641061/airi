# Gin REST, Resources, Transformers, Error Handling & Koanf Config

**Production locations:**

- `[context-name]/interfaces/rest/controllers/`
- `[context-name]/interfaces/rest/resources/`
- `[context-name]/interfaces/rest/transformers/` if explicit transformations merit a separate file
- `internal/platform/config/` (Koanf v2 + YAML)

HTTP and config tests are valuable, but **never substitute for domain tests**. Keep `gin.Context`, JSON binding tags, Koanf, and DB details out of the domain.

## Gin Controller / Handler tests

Use `httptest.NewRecorder`, `httptest.NewRequest`, and a `gin.New()` router. No live HTTP listener, external services, or database is needed to test the transport layer.

Test contracts that matter:

- Route/method and API version match documented OpenAPI paths.
- Valid body/query/route parameters are mapped to the correct application command or query.
- Missing, invalid JSON, wrong types, forbidden fields (when disallowed), and invalid pagination are rejected with **stable public error responses**.
- Domain error categories are mapped correctly (`400`, `404`, `409`, `422` depending on explicitly documented semantics).
- Success uses the intended response schema, status code, headers, and resource ID representation.
- Authorization and tenant/identity propagation work if relevant; never simulate auth by manually injecting trusted claims into a production-only path.
- Request cancellation propagates via `c.Request.Context()`.
- Sensitive internal errors do not leak as API bodies.

### Gin harness example

```go
func TestController_RejectsMalformedJSON(t *testing.T) {
    gin.SetMode(gin.TestMode) // Set once per test package; it is global state.
    router := gin.New()
    registerRoutes(router, newHandlerWithStubbedApplicationBoundary())

    req := httptest.NewRequest(http.MethodPost, "/api/v1/[entities]", strings.NewReader(`{"field":`))
    req.Header.Set("Content-Type", "application/json")
    recorder := httptest.NewRecorder()

    router.ServeHTTP(recorder, req)

    require.Equal(t, http.StatusBadRequest, recorder.Code)
    var got ErrorResponse
    require.NoError(t, json.Unmarshal(recorder.Body.Bytes(), &got))
    require.Equal(t, "INVALID_REQUEST", got.Code)
}
```

`registerRoutes`, `ErrorResponse`, and the application stub are placeholders for the actual project. Use consistent router setup; do not call the global `gin.SetMode` concurrently from multiple tests.

**Avoid:** testing Gin itself; asserting only `200 OK`; mocking domain aggregates in controllers; deserializing into `map[string]any` when a typed response contract exists.

## DTOs / Resources / Transformers

Only test explicit nontrivial transformations:

- Domain typed ID → external ID format; nested value conversions; lossless required fields.
- Null/optional semantics and omission rules.
- Precision, timezone, and enum code translation.
- No accidental exposure of private or sensitive internal fields.
- Error envelope matches the published API schema.

Do not test a trivial one-field `struct` assignment or generated encoder as a separate unit unless it protects an external compatibility requirement.

## Koanf v2 + YAML — configuration contracts

Configuration is not domain. Test the configuration loader with **controlled YAML bytes** (rawbytes provider), a fresh Koanf instance per test, and an injected environment provider where supported. A component test may use `t.TempDir()` for the real file-loading path.

High-value config scenarios:

1. Valid YAML loads into a typed config with expected nested keys.
2. Explicit env override takes precedence over YAML (e.g. `APP_DATABASE_URL`).
3. Missing required DB URL in a mode that requires DB returns a descriptive error.
4. Malformed YAML and wrong field types fail closed; no silent zero-value startup.
5. Invalid server port, negative max connections, or unsupported Gin mode fail validation.
6. Secrets never appear in errors, logs, or test snapshots.
7. No global shared config object between tests; avoid `t.Setenv` in parallel tests.

**Design principle:** expose a loader that accepts providers or a typed source; verify merge order and `Unmarshal`/validation. Do not hardcode configuration into `main.go` so tests need to start the whole application.

### Koanf contract pseudocode

```go
func TestConfig_EnvironmentOverridesYAML(t *testing.T) {
    yaml := []byte("database:\n  max_conns: 5\n")
    env := map[string]string{"APP_DATABASE_MAX_CONNS": "20"}

    cfg, err := config.LoadFromSources(yaml, env) // Injected-source API; implement in project.

    require.NoError(t, err)
    require.Equal(t, int32(20), cfg.Database.MaxConns)
}
```

No concrete Go loader signature is mandated by Koanf; this example states the behavior your own loader should enforce.

## Checklist

- [ ] Gin tested via `httptest`, no bound socket.
- [ ] HTTP requests/assertions validate the actual external contract.
- [ ] Typed error-to-status mapping and sensitive-data protection covered.
- [ ] Domain not mocked or imported into HTTP-specific test internals unnecessarily.
- [ ] Koanf YAML/env precedence, type errors, and missing required config verified.
- [ ] Main startup wiring is covered by a small smoke/component test if needed.
