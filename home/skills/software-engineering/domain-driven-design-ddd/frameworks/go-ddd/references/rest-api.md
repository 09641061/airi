# REST and Inbound Events — Adapt, Then Delegate

Source: guide §11. Gin is confined to REST/HTTP adaptation and applicable middleware/composition. Application/domain do not accept `*gin.Context` or transport resources.

## Place by feature and responsibility

Use `internal/[context-name]/interfaces/rest/` for REST endpoints over HTTP. For a small boundary, related handler, resources, and mapping can share one file. Introduce a feature package only when useful:

```text
interfaces/rest/
  routes.go
  enrollment/
    create.go
    create_test.go
    resources.go                 # optional related resources
    mapping.go                   # optional nontrivial transformation
```

`resources/` and `transform/` are valid optional subpackages, not mandatory steps in every request. Keep them feature-owned when extracted; avoid generic assembler frameworks, interfaces for simple copies, or one package per DTO. Do not add a redundant transport wrapper. `interfaces` is not a keyword. HTTP probes need not be modeled as REST resources.

## Implement a REST operation

1. Confirm the existing route/method, request/response shape, statuses, and applicable OpenAPI 3.1 contract before refactoring.
2. Bind input with bounded request sizes, safe parsing failures, and structural validation. Put JSON/Gin binding tags on resources here, not domain objects.
3. Construct an application input without passing transport types into the core.
4. Invoke the use case with `c.Request.Context()`; no database calls, domain invariants, or cross-context workflow in the handler.
5. Translate errors using `errors.Is`/`errors.As` and the published contract. Known absence/conflict/validation/authorization outcomes must not all become 500. Unexpected failures use a safe public response and appropriate observability.
6. Map the successful result explicitly to the public resource/status. A small local function or struct construction is enough unless transformation complexity warrants extraction.

Authentication/middleware implements HTTP mechanics; application/domain keep the authorization rules they respectively own. Preserve routes, payloads, statuses, and error schemas during architectural moves. Do not blindly impose a new status or error format on an existing API.

## Consume incoming messages

Location: `internal/[context-name]/interfaces/events/`.

- Decode/validate envelopes and payloads; interpret delivery identity and metadata.
- Adapt the message to an application command and propagate available context/deadlines.
- Delegate business behavior to application; a message callback is not a domain service.
- Ack only after the required durable processing succeeds. Define failure retry, duplicate handling, poison-message/dead-letter behavior, and cancellation according to the broker contract.
- Define domain event types with their aggregate, not in this delivery package. Outbound publication belongs in infrastructure.

Durable delivery, deduplication, and transaction coordination require explicit design; see [persistence](persistence.md) and [context integration](context-integration.md). An inbound ACL can live under `interfaces/acl/` only for actual model/contract translation; it is not an obligatory facade.

## Verify at the correct scope

Co-locate unit-level Gin/`httptest` tests with the handler. Cover success, malformed input, relevant absence/conflict/authorization/rejection, safe server-error output, resource mapping, and cancellation. A real network server is not necessary for these tests.

HTTP plus real storage is integration under `/test/integration/[context-name]/rest/`; incoming-message integration goes under the corresponding `events/` responsibility. Test full system journeys under `/test/e2e`. A tool such as `httptest` does not determine test scope; dependencies and guarantees do. See [testing](testing.md).
