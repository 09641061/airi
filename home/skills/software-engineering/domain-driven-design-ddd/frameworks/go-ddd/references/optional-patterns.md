# Optional patterns

These patterns are not part of the default. Adopt each when a concrete need justifies it; otherwise they add ceremony without paying rent.

| Pattern | Use it when… |
| --- | --- |
| Separate commands/queries or read model | Read/write paths or scaling needs have genuinely diverged. |
| Domain service | A business rule does not naturally belong to one entity or value object. |
| Domain event | Another part of the domain needs to react to a fact that occurred. |
| ACL | A foreign model or language would leak into the consuming context. |
| Outbox / saga / compensation | A process crosses transaction boundaries and must recover reliably. |

## Commands & queries (CQRS-lite)

Adopt only when read paths genuinely diverge from write paths — different query shapes, different latency budgets, different stores. Most bounded contexts keep one repository and let the read shape live in a dedicated query service or projection. Don't split unless the divergence is real.

## Domain services

A domain service holds a business rule that does not fit one entity or value object — e.g., a pricing policy that combines rules from several value objects. Keep them stateless, named after the rule, and call them from the aggregate or application layer (never from a transport adapter).

## Domain events

A domain event is an immutable fact that already happened in the past ("OrderSubmitted", "PaymentCaptured"). Publish them from the aggregate after a successful state transition. Consumers (other contexts, projections, integrations) own their ACL port and translate provider semantics — they do not import another context's events verbatim.

## Anti-corruption layer (ACL)

The consumer owns its ACL port. Translate provider semantics instead of importing another context's internals. Common shapes:

- Wrap a remote API behind a domain port; expose only what your context needs.
- Translate a foreign data model into your value objects at the boundary.
- Version your ACL independently from the upstream; never let the upstream break your invariants.

## Outbox / saga / compensation

When a process crosses transaction boundaries (e.g., "submit order → reserve stock → charge payment → notify warehouse"), you need reliable recovery. Patterns:

- **Transactional outbox** — write the domain event to an outbox table inside the same transaction as the state change; a separate worker dispatches it.
- **Saga / process manager** — orchestrates steps with explicit compensations; each step has an "undo" the manager can call on failure.
- **Idempotency keys** — every external call carries a key so retries don't double-charge or double-notify.

Treat remote calls as fallible and time-bounded; use idempotency and explicit recovery where needed.

## When NOT to add these

- "We'll need it eventually" — no, you won't, until you do, and the boundary is small enough to refactor then.
- "The book says so" — the book describes the option; your context decides whether to use it.
- "It's symmetric with other contexts" — symmetry is not a goal; clarity per bounded context is.