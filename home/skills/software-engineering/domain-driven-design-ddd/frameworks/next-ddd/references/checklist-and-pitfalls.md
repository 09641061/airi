# Checklist and Pitfalls

[Skill overview and workflow](../SKILL.md). Examples target Next.js 16 and React 19.3; verify project versions.

## Checklist

Before merging a bounded context, verify:

1. The feature is explicitly remote or rich-domain; any local Domain invariants work without React, Next.js, Zod, or IO.
2. Commands and queries live in `application/commands/` and `application/queries/`; handlers depend only inward and on consumer-owned ports.
3. Infrastructure owns HTTP/fetch, OpenAPI contracts, runtime provider validation, and ACL translation.
4. Composition is server-only at the edge; protected adapters cannot leak credentials or data between requests.
5. Actions and Route Handlers authenticate, authorize, validate, and map typed errors without exposing technical details.
6. Cache wrappers and invalidation stay outside Application; keys and policies prevent cross-user or cross-tenant disclosure.
7. Routes are thin, Server Components are the default, and server reads avoid loopback HTTP.
8. Client props are serializable; presentation has no application services; state and effects are justified.
9. Tests cover optional local domain invariants, handlers with a fake writer (one create call, full command and backend-generated ID propagation, no category lookup), optional category-query ACL semantics, adapter contract/error translation (especially 422 CATEGORY_NOT_AVAILABLE), remote-schema/OpenAPI constraint drift, and server authorization/validation boundaries, including cross-tenant access, cache isolation, sanitized unexpected errors and cause stacks, token/PII redaction (including nested causes and malicious stacks), generated IDs versus validated trusted-upstream IDs (reject malformed/overlong values and ignore browser IDs), correlation headers/log metadata for every remote operation, and successful-write redirects even when invalidation, redaction, or synchronous/asynchronous telemetry fails. Verify technical failures keep their cause for protected diagnostics while clients receive only stable, uncertain-outcome guidance.
10. Remote commands have no preliminary lookups unless they provide concrete additional value; Spring remains authoritative and any optional lookup cannot promise consistency. Every remote operation propagates correlation and retains protected diagnostic context for unexpected errors.
11. Any additional model, transform, component, or abstraction has a clear semantic responsibility.
## What To Avoid

1. Generic dumping grounds such as an unstructured `application/use-cases/` or `utils/`; a meaningful use-case directory name is not itself an architectural violation.
2. Commands/queries in Domain, CQRS contracts disguised as domain services, or outbound port definitions hidden in Infrastructure.
3. Application importing adapters, Next.js caching APIs, React, or OpenAPI transport models.
4. Business rules enforced only in schemas, UI-only authorization, or trusting client-supplied identity.
5. Shared caches of session-dependent data, raw backend errors in UI, and sentinel identifiers such as `0`.
6. Unnecessary Route Handlers, server-to-self HTTP calls, ceremonial DTO/mapper classes, and centralized adapter-selection switches in business code.
7. Fetching inside presentation, redundant derived state/effects, mutable rendering, and over-generalized forms.

This guide keeps business meaning in Domain, commands/queries and orchestration in Application, IO and foreign-model translation in Infrastructure, and framework/UI concerns at the Interfaces and routing edge.
