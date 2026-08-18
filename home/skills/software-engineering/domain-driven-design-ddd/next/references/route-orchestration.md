# Route Orchestration

`app/` files should coordinate, not contain domain logic.

## Responsibilities

1. Map route params and search params into queries.
2. Invoke query services or server actions.
3. Render loading, error, empty, and success states.
4. Pass only serializable props to Client Components.

Use these files as needed:

1. `page.tsx`
2. `layout.tsx`
3. `loading.tsx`
4. `error.tsx`
5. `not-found.tsx`

## Route Handlers and Proxy

Use the right boundary for the job.

1. Use **Server Actions** for app-owned mutations.
2. Use **Route Handlers** for webhooks, BFF endpoints, and non-form HTTP APIs.
3. Use **Proxy** for request-time redirects, rewrites, and header logic.

In Next.js 16, Middleware is now called **Proxy** and it defaults to the Node.js runtime.
Keep Proxy thin: use it for pre-route checks, not for full authentication logic.
Real authorization should live in layouts, server actions, or the data-access layer.
