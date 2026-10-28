# Errors — Meaning Across Boundaries

Source: guide §9, with port ownership in §7 and HTTP translation in §11. An error is a contract, not a message string to compare or expose.

## Establish categories and ownership

| Meaning | Owner | Handling |
|---|---|---|
| Aggregate/policy rejection | Owning domain package | Sentinel for a closed outcome; typed error when structured data is needed |
| Lookup absence / persistence conflict | Consumed port contract, often application | Adapter translates driver-specific outcomes into the declared contract |
| Provider model or failure | Consumer-owned integration boundary | Translate to the consumer's meaning without leaking provider internals |
| HTTP response | `interfaces/rest/` | Match known categories to documented status and safe public payload |
| Unexpected technical failure | Relevant technical boundary, observable at request/process level | Preserve useful context and avoid leaking credentials/internal details |

Do not define PostgreSQL repository methods inside the domain merely because an error is being illustrated. Definitions, driver translation, and HTTP mapping are separate files/packages. Consult the guide's examples in those separate locations.

## Specify absence deliberately

- Singular lookups default to an explicit not-found error in this project.
- A genuinely optional lookup may instead promise a presence flag or `(nil, nil)` consistently; audit every caller before changing that contract.
- `(T{}, err)` is idiomatic and is not an ambiguous magic failure value when the caller checks the error.
- Empty collections normally represent successful reads; they do not imply missing infrastructure or a failed query.
- Distinguish absence, conflict, domain rejection, cancellation/timeout, and unexpected failure where callers need different behavior.

## Preserve or translate meaning explicitly

Use `errors.Is` for sentinel categories and `errors.As` for typed errors; no message matching or direct equality on wrapped values. Use `%w` when preserving a cause is part of the contract. Do not wrap nil or accidentally return nil when an operation such as commit failed.

Translate at **each real boundary**, not only once globally: driver to port, provider to consumer, use case to HTTP. Only HTTP chooses statuses. Do not expose `err.Error()` as a public response; preserve published error schemas and report unexpected failures safely through observability.

Keep request context explicit through I/O, normally as the first parameter. Respect standard/framework signatures, adapting from `c.Request.Context()` at HTTP entry. Do not store context in business structs, pass nil, or replace a request context with an unrelated background context. Pure calculations do not need context by default.

## Verification

Test wrapped-category matching, typed fields, absence alternatives, conflict differentiation, cancellation propagation, safe HTTP output, and unexpected-error handling. Verify that repository tests cover actual driver translation and that unit tests use the same contract in fakes. Keep API error changes separate from architectural moves.
