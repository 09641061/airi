# Reads and Caching

[Skill overview and workflow](../SKILL.md). Examples target Next.js 16 and React 19.3; verify project versions.

## Reads and Caching

1. A Server Component or `interfaces/server/reads.ts` authenticates/authorizes a protected read, creates a request context, composes the query service with it, and invokes it directly. Reads and all other remote operations must propagate correlation to their adapters and record sanitized unexpected/technical failures with operation and bounded-context metadata at their server boundary. Do not make a loopback HTTP request to the application's own Route Handler.
2. Map and validate awaited route `params` / `searchParams` at the edge; in Next.js 16 these request props are asynchronous. Pass a plain query to Application.
3. Stream slow reads with `loading.tsx` or `Suspense`. `Suspense` provides a streaming boundary; it does not itself cache data or make it static.
4. Keep Next.js caching wrappers in Interfaces or another server edge, never in the application query service.

With Next.js 16 Cache Components enabled, `use cache`, `cacheLife`, and `cacheTag` can cache deliberately shareable reads. For example, an edge wrapper for a **public catalog only** may use `cacheLife('hours')` and `cacheTag('products:public')`. It must call a public-only adapter with no session credentials; deterministic output alone is not sufficient to justify a shared cache.

Protected reads are uncached by default in this guide. Read `cookies()` and `headers()` outside cached scopes, and never capture a session in a shared cached closure. If protected caching is later justified, authorize before access, include every relevant identity/tenant/filter dimension in the cache key, and design permission-change invalidation and tenant-scoped tags. Tags are invalidation labels, not authorization boundaries or cache keys.

`cacheComponents: true` enables the Cache Components / partial prerendering model in Next.js 16; runtime-dependent content needs an appropriate dynamic/Suspense boundary. It is not permission to cache all data. Do not copy older experimental flags without checking their version-specific documentation.
