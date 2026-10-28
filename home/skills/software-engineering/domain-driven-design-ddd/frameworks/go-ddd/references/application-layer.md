# Application Layer

The application layer exposes and orchestrates use cases. It depends on domain behavior and contracts; it does not import Gin, concrete persistence adapters, engine transaction handles, or transport DTOs.

## Commands

Location: `[context-name]/application/commands/`

A Command expresses an application intention to change state; it is not a persistence model and not a domain object.

- Use a business-intent name such as `[action]_[entity]_command.go`, exported as `[Action][Entity]Command`.
- Carry only the intent, identifiers, and operation constraints needed by the use case.
- Validate structural input at the entry boundary. Domain behavior must still enforce business rules.
- Do not add Gin, REST DTO, query-client, ORM, or driver-specific fields.
- If a project already keeps command contracts in another package, keep that location as long as they remain application inputs.

**Checklist**

- [ ] Command names communicate a business intention.
- [ ] No HTTP or persistence-specific fields are introduced accidentally.
- [ ] Required input data is present and documented.
- [ ] Domain rules are rechecked by domain behavior; input validation is not mistaken for business validation.

## Queries

Location: `[context-name]/application/queries/`

A Query requests information without modifying business state.

- Use a name such as `[intent]_query.go`, exported as `[Intent]Query`.
- Keep contracts focused on an information use case.
- Make optional criteria and absence semantics explicit.
- Validate filtering, sorting, pagination, and field constraints; bound page sizes and define deterministic ordering.
- Return a focused application read projection when rebuilding an aggregate is unnecessary. Keep read DTOs/projections out of `domain/`.
- Queries must not mutate aggregates or business state.

**Checklist**

- [ ] Query contracts are use-case-focused.
- [ ] Pagination limits are bounded and deterministic.
- [ ] Optional criteria and absence semantics are explicit.
- [ ] Read operations do not mutate aggregates or state.

## Command Services

Location: `[context-name]/application/commandservices/`

A Command Service coordinates a state-changing use case: obtain the needed aggregate, invoke domain behavior, persist the result, and coordinate side effects only when justified.

- Accept `context.Context` as the first parameter and use constructor-injected ports.
- Invoke domain methods for business rules; do not move invariants into orchestration.
- Preserve business meaning in returned errors — wrap with `%w` and never rebuild the message by string concatenation.
- Use a transaction/unit-of-work abstraction only if the operation and selected storage engine require it. Do not assume relational transaction semantics across technologies.
- Make all-or-nothing guarantees, concurrency behavior, and retries explicit when the use-case contract needs them.
- Do not accept `*gin.Context` or concrete storage/client types.
- Wire implementations at the composition root.

**Checklist**

- [ ] Depends on domain repository interfaces.
- [ ] Calls real domain methods to enforce rules.
- [ ] Errors preserve business meaning.
- [ ] State-changing orchestration follows documented consistency guarantees.
- [ ] Constructor wiring happens at the composition root.

## Query Services

Location: `[context-name]/application/queryservices/`

- Execute read-only use cases with explicit absence and error semantics.
- Use a domain repository if returning aggregates is appropriate; define a separate read port if a projection better serves the query.
- Avoid generic all-purpose data-access services and direct database-implementation dependencies.
- Accept `context.Context`; use bounded pagination and stable sorting.

**Checklist**

- [ ] Reads are side-effect free.
- [ ] Read ports and models match actual use cases.
- [ ] No direct dependency on a specific database implementation.
- [ ] Sorting and pagination contracts are stable.

## Checklists

**Context and errors:** `context.Context` is the first parameter of any function that performs I/O, is never stored in a struct, and is never `nil`; business failures are sentinel or typed errors matched with `errors.Is`/`errors.As`.

**Application:** command and query contracts express use-case intent, not transport or storage representation; orchestration depends on domain contracts and calls real domain behavior; reads are side-effect-free; writes state their consistency/concurrency guarantees; constructor wiring stays outside domain and application packages.
