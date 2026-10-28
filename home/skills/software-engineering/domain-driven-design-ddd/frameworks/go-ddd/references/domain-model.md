# Domain Model — Invariants and Lifecycle

Source: guide §§1–2, 5–6. Keep the model in the cohesive aggregate package, typically `internal/[context-name]/domain/[aggregate]/`. A small context may keep one cohesive domain package. Use the guide for example implementations; do not generate every tactical building block.

## Establish the model

Before coding, identify the behavior, owning aggregate, initial state, allowed transition, rejected inputs, and required consistency. Separate aggregate invariants from application preconditions such as record existence and workflow authorization. If these facts are unknown, ask rather than inventing business rules.

Reference other aggregates by identity unless a documented local consistency need warrants otherwise. Do not derive aggregate boundaries from tables. Give a domain service a home only for a business policy that lacks a natural entity/value-object owner; prefer pure calculations over provided values. A genuinely needed external capability is a narrow domain-owned contract with an outside adapter, not a driver/client import.

## Choose a value representation

| Need | Decision and limitation |
|---|---|
| Distinct primitive type | A named type such as `CourseID` distinguishes types, but explicit conversions can bypass its constructor |
| Restrict arbitrary non-zero construction | A struct with an unexported field can be appropriate even for one primitive |
| Several attributes / normalization / equality | Define a cohesive value with deliberate representation and business semantics |
| Invalid zero value | Reject it in consuming constructors/operations; Go still permits zero values |
| Mutable members | Copy slices/maps/pointers as needed so aliases cannot violate ownership |

Validate fallible inputs in constructors. Do not add errors to infallible construction just for symmetry, or claim that constructors make invalid values impossible. Verify decoding and persistence reconstruction paths as well as direct calls. Keep storage/HTTP tags and technical frameworks outside the model.

## Implement transitions safely

1. Validate receiver/initialization and operation inputs where required.
2. Check every precondition before mutating state, or compute a candidate state that can be committed together.
3. Apply the accepted transition through a business-named method, not exported setters.
4. Record a success event only if the behavior requires one.
5. On rejection, leave all state and pending events unchanged.

Test explicitly that an update does not assign an invalid field and then return a validation error with the object already changed. Do not treat a validated wrapper/flag as proof of safety when exported embedded state can be mutated afterward.

Do not introduce base Entity/Aggregate/ValueObject interfaces, factory hierarchies, or an injected publisher to satisfy a diagram. Split files by behavior within the aggregate before extracting packages.

## Distinguish creation from reconstitution

Creation may choose initial state and record a creation fact. Reconstitution restores persisted identity/state without generating IDs, current creation timestamps, or creation events. Define valid historical states and schema/model compatibility separately from today's creation constraints. Reject corrupt representations rather than either reapplying every new creation rule blindly or bypassing all invariants.

Control time/identity when their values affect behavior. Choose the source according to actual requirements, not a universal ban on database defaults.

## Events and pending-state ownership

Events are optional past-tense business facts. Keep domain facts with the aggregate; published integration contracts belong to a deliberate cross-context boundary. Include only necessary payload, identity, and occurrence time. A Go struct is not inherently immutable: copy mutable content and returned collections; do not expose the aggregate's event buffer.

For events requiring durable publication:

1. Capture a snapshot of pending facts and map to the required integration contract.
2. Persist state and the outbox/message record with the engine's actual atomic guarantee.
3. Acknowledge/clear pending events only after successful commit, or discard/reconstruct a failed aggregate before retrying.
4. Publish through a retrying relay with consumer deduplication/idempotency and explicit crash-window behavior.

Destructive `PullEvents` before a fallible write can lose events when retrying the same instance. Outbox and idempotency keys do not automatically prove exactly-once effects. Details: [persistence](persistence.md), [context integration](context-integration.md).

## Verify before accepting

- [ ] Valid, invalid, zero-value, and boundary inputs have explicit outcomes.
- [ ] Transitions enforce invariants with real domain objects, including unchanged state/events after rejection.
- [ ] Mutable references cannot bypass ownership; aggregate references and package boundaries are justified.
- [ ] Reconstitution preserves identity/history without creation side effects.
- [ ] Policies, events, and collaborators exist for concrete requirements, not scaffolding.
- [ ] Domain imports contain no Gin/HTTP, persistence/configuration clients, logging frameworks, bootstrap, or foreign private model.
