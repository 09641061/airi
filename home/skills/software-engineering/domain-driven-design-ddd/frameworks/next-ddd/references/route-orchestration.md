# Route Orchestration, Route Handlers, and Proxy

[Skill overview and workflow](../SKILL.md). Examples target Next.js 16 and React 19.3; verify project versions.

## Route Orchestration

`app/` files coordinate routing, not domain logic. A thin page delegates to a context server read/orchestration function, then renders context components.

Responsibilities:

1. Await and validate route params and search params into application queries.
2. Invoke authorized server orchestration directly, without an internal HTTP hop.
3. Render loading, error, empty, and success states.
4. Pass serializable view models to Client Components, never repositories or application services.

Use `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, and `not-found.tsx` as needed. Framework-required client files such as `error.tsx` do not make the entire route a client tree. Layout checks can improve navigation UX but are not sufficient authorization for reads or mutations.
## Route Handlers and Proxy

Use the right boundary for the job:

1. **Server Actions** for app-owned mutations.
2. **Route Handlers** for necessary HTTP boundaries: webhooks, external consumers, or a justified browser-facing BFF endpoint. They authenticate, authorize, validate, compose application services, and translate typed outcomes to HTTP responses. Verify webhook signatures where applicable.
3. **Proxy** for request-time redirects, rewrites, and header logic.

In Next.js 16, Middleware is renamed **Proxy**, which uses the Node.js runtime. Keep Proxy thin; pre-route checks are not the final security boundary. Enforce real authorization at each protected server operation and authoritative data boundary, including requests that bypass normal navigation.

Client-side fetching can be justified for polling, browser-only APIs, or interactive client caches. Encapsulate that transport in an appropriate adapter/hook boundary, keep secrets server-side, and authorize the target endpoint. This exception does not justify scattering `fetch` calls through presentational components or routing every server read through a Route Handler.
