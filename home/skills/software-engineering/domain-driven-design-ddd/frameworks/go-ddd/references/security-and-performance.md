# Security and Performance

## Security minimum (every production HTTP service)

- **HTTP timeouts** on the `http.Server`: `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, `IdleTimeout`. A request that hangs forever is a DoS.
- **Request body size limits** via `http.MaxBytesReader`. Cap by endpoint; default 1 MiB.
- **Authentication** at the transport boundary. Don't invent your own session handling.
- **Authorization** at the application or domain layer. The transport only knows identity; the application decides what the identity can do.
- **Input validation** at the transport layer (`go-playground/validator/v10` tags, plus the value object constructors in the domain).
- **Parameterized SQL** — never string-concatenate user input into queries.
- **Graceful shutdown** via `signal.NotifyContext` and `srv.Shutdown(ctx)` with a deadline.
- **Secure configuration** — secrets from environment variables or a secret manager, never in source.
- **TLS termination** at the load balancer or reverse proxy in front of the Go process; the Go process listens on plain HTTP behind a trusted network.
- **Dependency hygiene** — `govulncheck ./...` in CI.

```go
srv := &http.Server{
    Addr:              ":8080",
    Handler:           mux,
    ReadHeaderTimeout: 5 * time.Second,
    ReadTimeout:       15 * time.Second,
    WriteTimeout:      30 * time.Second,
    IdleTimeout:       60 * time.Second,
}

ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer stop()

go func() {
    if err := srv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
        slog.Error("server", "err", err)
        os.Exit(1)
    }
}()

<-ctx.Done()
shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
if err := srv.Shutdown(shutdownCtx); err != nil {
    slog.Error("shutdown", "err", err)
}
```

## Multitenancy

If the service is multi-tenant, decide how the tenant travels before writing the first query.

- **Tenant on the context.** Add a `TenantID` to `context.Context` via a typed key in the application layer. The transport middleware extracts it (header, JWT claim, subdomain) and the application service reads it.
- **Filter at the repository.** Every query includes `WHERE tenant_id = $N`. The repository port accepts a `TenantID` (or a `Ctx` helper) so the application can't forget.
- **Don't trust the database row alone.** Add a `CHECK` constraint that matches the application filter, so a forgotten `WHERE` clause fails at the DB.
- **Test the cross-tenant leak.** Integration tests that create two tenants and verify that user A's queries never see user B's rows.

## Performance

Measure before optimizing. The usual suspects in a Go + PostgreSQL service:

1. **SQL queries.** The slowest line in the request is almost always the DB. Check `EXPLAIN ANALYZE` on hot queries.
2. **Indexes.** Composite indexes ordered by equality columns first, then range columns. Add indexes for the actual filter+sort pattern the query uses, not the columns the ORM likes.
3. **Database round trips.** N+1 patterns in repository code. One aggregate load, not one query per item.
4. **Connection pool.** `pgxpool.Config{MinConns, MaxConns}` matched to PostgreSQL's `max_connections`.
5. **Network calls.** Outbound HTTP, ACL calls. Timeouts, retries, circuit breakers. Don't issue a synchronous HTTP call inside a critical request path if you can avoid it.
6. **Payload size.** Trim response bodies; don't return the full aggregate when the client only needs three fields.
7. **Allocations.** Hot-path profiling with `pprof`. Don't pre-allocate without measurement.
8. **Goroutine leaks.** Always `defer cancel()` on a context, and use a leak detector in tests.
9. **Lock contention.** If the application uses shared state, profile before adding locks.

## Profiling tools

- `pprof` — `import _ "net/http/pprof"` on a debug-only listener. Use `go tool pprof http://localhost:6060/debug/pprof/cpu` to capture a CPU profile.
- `go test -bench` — micro-benchmarks for hot paths. Always pair with `-benchmem` to see allocations.
- `go test -race` — race detector in CI. Don't ship race-prone code.
- `expvar` or Prometheus for runtime metrics (goroutine count, GC pause, heap size).

## Don't over-engineer

Synthetic benchmarks don't pick an architecture. Real traffic, real schema, real load does. Optimize after the first 100k requests, not before.

## Checklist

- [ ] `http.Server` has read/write/idle timeouts
- [ ] Request body size is capped with `http.MaxBytesReader`
- [ ] Authentication at the transport boundary; authorization in the application layer
- [ ] All SQL is parameterized
- [ ] Secrets come from environment / secret manager, never from source
- [ ] Graceful shutdown wired to `SIGINT` / `SIGTERM` with a deadline
- [ ] `govulncheck ./...` runs in CI
- [ ] Multi-tenant queries include the tenant filter; `CHECK` constraints back it up
- [ ] `pprof` endpoint exists and is reachable in non-production environments
- [ ] `go test -race` is part of the default test command in CI
