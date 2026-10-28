---
name: go-ddd
description: Implement, audit, or refactor Go DDD bounded contexts with Gin at interfaces/rest, cohesive aggregate and feature packages, consumer-owned ports, context-owned adapters, explicit consistency and error contracts, safe event delivery, and process composition outside the domain. Keep unit tests beside code and integration/E2E under root test. Use for Go/Gin architecture and bounded-context work without imposing a database, ORM, configuration library, or full layered scaffold.
---

# Go DDD — Operational Workflow

Use this skill to implement a bounded-context feature, audit architectural boundaries, or refactor a Go/Gin backend. DDD models business meaning; it is not a directory checklist. Prefer a modular monolith until deployment requirements justify distribution. Do not invent aggregates for simple CRUD, or confuse CQS with a requirement for separate read/write stores.

Use an organization-approved stable Go release, standard `testing`/`httptest`, `errors`, and request context. Document HTTP contracts with OpenAPI 3.1; use structured `log/slog` and operationally justified OpenTelemetry at the appropriate boundaries. Preserve existing project contracts and treat dependency/toolchain upgrades as explicit changes, not incidental refactor steps.

## Authority and scope

The architectural source is `~/personal-notes/software-engineering/domain-driven-design-ddd/go/go-gin-ddd.md` (repository-relative: `software-engineering/domain-driven-design-ddd/go/go-gin-ddd.md`). If that checkout is elsewhere, locate it rather than assuming this path exists on every machine.

- Reviewed guide content: Git blob `c0cd1f01149be86697dc5bd91501247a8f29311c`.
- Guide repository base commit: `d584a0ce145a660504858e9e629bfd9820f5c4aa`; the reviewed guide update was **uncommitted**, so that commit alone does not identify this revision.
- This skill and its nine references derive from that content. Compare `git hash-object <guide-path>` before claiming synchronization with a later revision. A mismatch requires semantic review, not automatic rejection of the user's code.
- The guide's own pending-status marker is not changed by updating this skill. Linked `go-tdb` architecture remains separately unsynchronized; see [testing](references/testing.md). Do not claim ecosystem-wide alignment.

Use the guide for rationale, complete examples, and pinned repository evidence. References below provide decisions and checks rather than copies of the guide. If the guide is unavailable, say so and use the recorded baseline; do not claim a live comparison.

## Non-negotiable working rules

1. **Respect the requested mode.** Audit-only means findings and a correction plan, not edits. Implementation/refactoring permission does not authorize unrelated API, schema, dependency, or tooling changes.
2. **Preserve contracts.** Inventory routes, methods, payloads, statuses, business rules, ownership, and persistence semantics before moving code. Separate intentional contract changes from architectural moves.
3. **Keep policy inward.** Domain contains business behavior; application coordinates use cases through consumed ports. Neither imports Gin, concrete adapters, configuration, or engine transaction handles.
4. **Use inbound interfaces deliberately.** `interfaces/rest/` owns REST resources and handlers; `interfaces/events/` owns incoming message adaptation. Publishers and outbound clients belong in infrastructure. Place ACLs by direction, not name.
5. **Organize by context and responsibility.** Keep aggregate concepts cohesive. Keep use-case input/result/handler together when useful; `resources/` and `transform/` are optional, not obligatory packages.
6. **Make failures and consistency explicit.** Match errors with `errors.Is`/`errors.As`, propagate request context, check commit results, and document callback retries. No unsafe external effects in retryable transactions or destructive event consumption before persistence succeeds.
7. **Keep composition outside the model.** `cmd/api/` and optional `internal/bootstrap/` own initialization and cleanup. Shared packages require real compatible consumers and explicit ownership.
8. **Review growth, not just line count.** Review every hand-written Go file over 150 physical lines; split/move/merge/delete by responsibility or record a cohesion rationale. Never hand-edit generated output.
9. **Test continuously.** Unit tests stay beside code. Integration/E2E live under module-root `/test`, grouped by context and responsibility, and have explicit CI execution.
10. **Add only justified mechanisms.** No mandatory database, ORM, migration/configuration/DI library, event bus, outbox, interface pair, or empty layer. Existing useful organization need not be renamed merely to resemble examples.

## Execute one vertical slice

| Phase | Required work | Load when relevant |
|---|---|---|
| 1. Inspect | Read project instructions, module/workspace setup, imports, existing contracts, tests, and generated-code boundaries | [Architecture](references/architecture-and-structure.md) |
| 2. Specify | Name the behavior, owning context, invariants/preconditions, failure outcomes, authorization, and consistency guarantee | [Domain](references/domain-model.md), [errors](references/errors.md) |
| 3. Model | Implement/test only the values and transitions this behavior requires; test zero values and unchanged state after rejection | [Domain](references/domain-model.md), [testing](references/testing.md) |
| 4. Orchestrate | Define input/result and narrow consumed ports; implement the use case with real domain objects and boundary fakes | [Application](references/application-layer.md) |
| 5. Adapt | Implement mapping/reconstitution, concurrency, and actual atomicity; run real-engine contract tests | [Persistence](references/persistence.md) |
| 6. Expose | Add REST or inbound-message adaptation, safe error translation, or justified model translation | [REST/events](references/rest-api.md), [integration/ACL](references/context-integration.md) |
| 7. Compose | Wire dependencies and verify startup, shutdown, cancellation, and required telemetry | [Runtime](references/runtime-and-observability.md) |
| 8. Verify | Run applicable checks; review imports, oversized files, contract stability, and critical E2E behavior | [Testing](references/testing.md), [architecture](references/architecture-and-structure.md) |

Tests, error contracts, and observability accompany the slice; none is postponed to a final project phase. Load relevant references before making their decisions, not every reference for every task.

## Audit and refactor procedure

For an audit, produce:

1. A bounded-context/package/import map, including published APIs and cross-context data access.
2. Findings with severity, exact `path:line`, observed evidence, impact, and proposed correction. Distinguish verified defects, design trade-offs, and hypotheses requiring execution.
3. A file-action inventory: split, move, merge, delete, or retain, including a decision for each hand-written file over 150 lines.
4. A test-gap/consistency matrix and ordered migration plan with contract-preservation checks.

For an authorized refactor, establish characterization tests first, then move one responsibility at a time. Do not replace the whole backend with a generated layered tree. Stop and request a decision when ownership, business rules, public behavior, or required atomicity cannot be established; report unavailable infrastructure instead of treating fake tests as proof.

## Delivery gate

- [ ] Imports and package APIs enforce the intended dependency direction; top-level `internal/` is not mistaken for sibling-context isolation.
- [ ] Domain invariants, zero values, reconstitution, and event ownership have explicit behavior.
- [ ] Ports belong to consumers; storage/generated types and transaction handles stay outside the core.
- [ ] REST, events, and ACL adapters delegate rather than implement business workflows.
- [ ] Bootstrap/shared packages have narrowly stated responsibilities and no hidden global dependency registry.
- [ ] File actions preserve cohesion; oversized-file review does not introduce artificial packages.
- [ ] Unit tests are co-located; tagged integration/E2E suites under `/test` actually run where required.
- [ ] Public contracts remain unchanged or their changes were separately approved.

Report changed paths, behavior preserved/changed, checks actually executed, failures/skipped checks with reasons, and remaining risks. Never report a template as runnable code or a test as passed without executing it.

## Guide-to-skill correspondence

| Guide sections | Operational reference |
|---|---|
| Introduction, core rules, placement, §17 | [Architecture and structure](references/architecture-and-structure.md) |
| §§1–2, 5–6 | [Domain model](references/domain-model.md) |
| §§3–4, 8, 16 | [Application layer](references/application-layer.md) |
| §§7, 10 | [Persistence and transactions](references/persistence.md) |
| §9 | [Errors](references/errors.md) |
| §11 | [REST and inbound events](references/rest-api.md) |
| §12 | [Context integration](references/context-integration.md) |
| §13 | [Testing](references/testing.md) |
| §§14–15 | [Runtime and observability](references/runtime-and-observability.md) |
| §18 | This source record, delivery gate, and correspondence table |

When updating a rule, compare all affected references, trees, examples, and commands with the guide. Record the reviewed content revision only after semantic review. Historical repositories inform the guide's rationale; they never override these rules simply because their current folders differ.
