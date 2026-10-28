# Context Integration — Contracts, ACLs, and Delivery

Source: guide §12, with event lifecycle in §6. A context owns its meaning and data. A shared database/client never authorizes cross-context repository, table, or private-model access.

## Decide whether translation is needed

1. Name provider and consumer, the capability/fact required, and its owner.
2. Compare identifiers, terminology, states, absence/errors, and consistency expectations. Similar names do not prove identical meaning.
3. Define the consumer-owned capability port and required types without exposing provider private aggregates.
4. Publish only the intentionally supported provider application API. An in-process API can be an inbound port; it is not an HTTP endpoint.
5. Add a facade/ACL only if stable adaptation or semantic protection is required; avoid pass-through layers.
6. Inject the consumer's adapter at composition and test the agreed translations and failure behavior.

## Place by direction, not by the label ACL

| Responsibility | Placement |
|---|---|
| Port the use case consumes | Consumer's application package, or a domain policy that genuinely consumes it |
| Adapter importing/calling another context's public API, even in-process | Consumer's `infrastructure/acl/` or provider-named integration package |
| Pure conversion using only application-owned contracts | Owning application feature |
| Inbound adaptation from an external calling model to this context's application API | `interfaces/acl/` when actual translation/protection justifies it |
| Published use-case contract | Provider's intentionally public application boundary |

An inbound facade is not automatically a DDD ACL; document which models it translates and who owns it. Do not place an outbound provider call in application merely because it avoids network I/O, or force every translation into `interfaces/acl/`.

Enforce imports through published APIs and avoid cycles. Top-level `internal/` does not isolate siblings. Never fix cycles by moving unrelated business contracts into shared. Translate provider outcomes into consumer meaning, distinguishing absence/rejection, timeouts/cancellation, and technical failure as required.

## Shared meaning versus technical reuse

A Shared Kernel requires explicitly co-owned domain concepts/invariants, joint change governance, and compatibility tests. A focused `internal/shared/kernel/` can express that deliberate decision, but is not required. Do not create it simply because two contexts have `UserID`, Money, or similarly named states.

Technical shared packages such as observability, HTTP middleware, or client factories require compatible actual consumers and ownership; they contain no business repositories or generic model DTOs. Process configuration may stay with bootstrap. See [architecture](architecture-and-structure.md).

## Events and failure coordination

Domain facts are not automatically public integration contracts. Translate and version only the facts another context actually needs. For durable delivery, persist the integration record atomically with the state using the engine's supported mechanism, then relay with explicit retries and idempotent/deduplicating consumption.

Audit crash windows, event identity, duplicate delivery, idempotency reservation/response persistence, and poison-message handling. Do not clear pending domain facts before a fallible commit or invoke non-repeatable remote effects inside retryable storage callbacks. Neither outbox nor an idempotency header alone provides exactly-once effects.

Prefer context-local transactions. A deliberate shared local transaction is a coupling decision, not proof of distributed atomicity. If remote work can succeed before a local failure, specify recovery/coordination instead of pretending rollback undoes it.

## Verify

- Unit-test semantic conversion with real consumer types and boundary fakes.
- Under `/test/integration/[context-name]/acl/` or `events/`, verify real provider/broker contracts where required, including failures, timeout, and duplicates.
- Put genuine multi-context critical journeys under `/test/e2e/journeys/`.
- Verify imports do not bypass the published API or leak provider repositories/private types.
- Report unverified guarantees explicitly, not as completed integration merely because in-process calls compile.
