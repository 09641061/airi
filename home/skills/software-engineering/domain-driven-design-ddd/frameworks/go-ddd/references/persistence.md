# Persistence — Contracts, Mapping, and Atomicity

Source: guide §§7, 10; event lifecycle in §6. The guide contains the illustrative versioned repository, PostgreSQL conditional-write helper, and transaction-provider templates. Adapt their contracts together rather than copying fragments with undeclared types.

## Specify the consumed contract

Before implementing an adapter, document:

| Concern | Required decision |
|---|---|
| Ownership | Which use case/domain policy consumes the port and declares its operations? |
| Shape | Aggregate persistence, simple store, or focused read projection? |
| Absence | Explicit not-found error by default for singular lookups; any optional-result alternative must be documented |
| Concurrency | Expected-version conditional write, locking, or another engine-supported guarantee? |
| Atomicity | Which state changes/messages must commit together? |
| Retries | Which failures are retried, by whom, with what limit/cancellation behavior? |
| Compatibility | Which stored representations and historical states can be reconstructed? |

Use `internal/[context-name]/infrastructure/persistence/[technology]/` for implementations. Ports normally belong beside consuming application code; a genuinely consuming domain policy can own its narrow collaborator. Do not inject repositories into aggregates just to lazy-load children. A focused CRUD/read port does not require an invented rich aggregate or generic repository hierarchy.

## Implement the adapter boundary

- Keep rows, document schemas, ORM tags, driver types, and mappings inside the adapter. Reconstitute the domain deliberately; never reset identity/time or emit creation events while reading.
- Do not leak sqlc `DBTX`, `Queries`, `Querier`, pgx, SQL, or ORM types through the consumed port. Generated contracts are technical implementation details, not automatically application ports.
- Constructors normally return concrete types; methods follow their port's result contract. A package such as `postgres` already identifies the implementation technology.
- Pass request context through begin/query/write operations where APIs support it; translate driver errors into owned port outcomes.
- Share a technical client factory only for real compatible consumers. Repositories, schema access, and mappings remain context-owned.
- Soft delete, database defaults, and read-after-write are decisions driven by lifecycle/engine needs, not universal DDD rules. A read-after-write alone does not prevent lost updates.
- Review adapter files over 150 lines by responsibility. Generated output/vendor is excluded from manual splitting; update SQL/schema/generator settings and regenerate reproducibly.

## Select a consistency mechanism

| Situation | Candidate and required check |
|---|---|
| Single aggregate, optimistic concurrency | Read an expected version and compare it atomically on update while incrementing the stored version |
| Single aggregate, lock-based update | Load/change/write under the engine's actual lock/transaction; document callback retry behavior |
| Several repositories need one atomic operation | A narrow provider supplies explicitly transaction-bound capabilities to the application callback |
| Engine lacks the requested atomic primitive | State the limitation and obtain a business/coordination decision; do not promise SQL semantics |

For versioned SQL writes, handle both execution errors and `RowsAffected()` errors. Zero affected rows may mean stale version or absence; define whether those are one conflict outcome or require stronger differentiation under concurrency. Transaction-local version tokens/results are provisional until successful commit.

## Implement transaction binding, not just a named interface

Application declares the required consistency; the adapter owns the concrete handle. A provider must:

1. Begin with the appropriate request context/isolation settings.
2. Construct every supplied repository/capability using that **same transaction**.
3. Invoke the callback with those capabilities. Inside it, use the supplied stores, not pool-backed repositories injected elsewhere.
4. Roll back/clean up on failure and preserve the original failure meaning.
5. Check commit explicitly; never turn a commit failure into success or wrap an unrelated nil error.
6. Return success only after commit. A local rollback does not reverse a remote effect.

A context-only callback does not prove binding. Do not pass engine handles into the core or hide them in context as a service locator. Avoid a generic repository registry; add only named capabilities the atomic use case requires.

Prefer context-local transactions. A shared local transaction across contexts needs an explicit ownership/coupling decision; no local transaction makes remote calls atomic.

## Callbacks, events, and retries

Check whether the selected engine/provider can repeat the callback. Keep external calls, broker publication, and other non-repeatable effects out of retryable callbacks. Define identity/time/input stability and idempotency when repetition is possible. Bound attempts, honor cancellation, and use appropriate backoff; no unbounded deadlock loop.

For durable integration facts, persist state and the outbox/message record with one supported atomic guarantee. Snapshot pending events instead of destructively clearing them before fallible persistence. Acknowledge after commit, or reconstruct a failed aggregate before reuse. A relay and idempotent consumers provide a deliberate at-least-once design, not a blanket exactly-once promise. See [domain lifecycle](domain-model.md) and [context integration](context-integration.md).

## Integration evidence required

Under `/test/integration/[context-name]/persistence/`, exercise the actual selected engine and production-relevant migrations/constraints. Verify mapping/reconstitution, absence/error translation, uniqueness, conditional writes, concurrent updates, rollback, cancellation, commit failures where feasible, and state/message atomicity when applicable.

A memory fake, another database, a mutex, a callback signature, or passing unit mocks does not prove these guarantees. Report unexecuted or infeasible checks explicitly; do not silently skip missing infrastructure and call the adapter verified.
