# Component Tests (Client & Server Components)

## Client Components. Location: `components/` and Client Components

Use **Vitest + React Testing Library + jsdom**.

Test observable behavior:

- Rendering of relevant content
- User interactions
- Loading, success, empty, and error states
- Validation messages
- Accessibility roles, labels, and keyboard behavior
- Callback or action invocation caused by user behavior

Prefer accessible queries:

```ts
screen.getByRole()
screen.getByLabelText()
screen.getByText()
```

Use `userEvent` for interactions. Do not test internal React state, implementation details, or the exact component tree.

## Server Components

Test Server Components through their rendered behavior and their integration with application services.

- Test the content shown for successful, empty, and failing states
- Mock application services or data boundaries in isolated tests
- Verify that relevant parameters are passed to the use case
- Test loading and error UI with the corresponding route boundaries
- Avoid asserting Next.js framework internals

Use integration or end-to-end tests when the behavior depends on routing, caching, or the real server runtime.
