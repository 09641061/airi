# Theming with CSS custom properties

Custom properties (`--name`) are **live** variables: they participate in the cascade and can be changed
at runtime. That is the difference from preprocessor variables, which resolve at build time — a theme
cannot be switched with Sass variables, it can with these.

## Scope and cascade

A custom property inherits like any other property. Declared on `:root` it is global; declared on a
component it is redefined for that subtree. That behaviour is what allows local themes — a dark section
inside a light page — without duplicating rules.

Consume with a fallback: `color: var(--text-primary, #111);`.

Runtime access from JavaScript:

```js
document.documentElement.style.setProperty('--accent', value);   // write
getComputedStyle(el).getPropertyValue('--accent');               // read effective value
```

## Two layers

1. **Primitives** — the raw palette: `--blue-500`, `--gray-50`.
2. **Semantic** — the usage: `--color-surface`, `--color-text-primary`, `--color-accent`.

Components consume **only** the semantic layer. Switching themes means redefining the semantic layer;
a component that consumes `--blue-500` cannot be rethemed. Name by usage, never by value.

This is the CSS implementation surface of design tokens — see
[design-systems](../../design-systems/SKILL.md) for the token model
itself, and [design-system-patterns](../../design-system-patterns/SKILL.md) for the wider system.

## Light/dark pattern covering all three states

The three states are: explicit light, explicit dark, and "follow the system".

1. Define the **complete light palette** on bare `:root`, unconditionally. No variable may have its only
   definition inside a media query.
2. Redefine only what changes under `@media (prefers-color-scheme: dark)`, scoped with
   `:root:not([data-theme="light"])` so an explicit light choice wins.
3. Redefine again under `:root[data-theme="dark"]`, so the toggle wins in both directions.
4. Give `body` an explicit token background — a transparent body inherits its container's and breaks the theme.

```css
:root {
  /* Light palette — complete, unconditional */
  --color-bg-canvas: #f8fafc;
  --color-bg-surface: #ffffff;
  --color-text-primary: #0f172a;    /* 15.8:1 on #fff — AAA */
  --color-text-secondary: #475569;  /* 5.9:1 on #fff — AA */
  --color-brand-primary: #1d4ed8;   /* 7.2:1 on #fff — AAA */
  --color-brand-focus: #2563eb;
  --color-border: #cbd5e1;
  --color-error: #b91c1c;

  --font-system: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --space-xs: 0.5rem;
  --space-sm: 0.75rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
}

/* Follow the system, unless light was chosen explicitly */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --color-bg-canvas: #0f172a;
    --color-bg-surface: #1e293b;
    --color-text-primary: #f8fafc;    /* 14.1:1 on #1e293b */
    --color-text-secondary: #94a3b8;  /* 4.8:1 on #1e293b */
    --color-brand-primary: #3b82f6;   /* 5.1:1 on #1e293b */
    --color-brand-focus: #60a5fa;
    --color-border: #334155;
    --color-error: #f87171;
  }
}

/* Explicit user choice wins in both directions */
:root[data-theme="dark"] {
  --color-bg-canvas: #0f172a;
  --color-bg-surface: #1e293b;
  --color-text-primary: #f8fafc;
  --color-text-secondary: #94a3b8;
  --color-brand-primary: #3b82f6;
  --color-brand-focus: #60a5fa;
  --color-border: #334155;
  --color-error: #f87171;
}

body { background-color: var(--color-bg-canvas); color: var(--color-text-primary); }
```

## Contrast is part of the token definition

Every theme must independently satisfy WCAG 2.2 AA: **4.5:1** for normal text, **3:1** for large text,
UI component boundaries and focus indicators. Record the measured ratio next to each token, as above —
it is the only way the constraint survives a palette edit.

## Common mistakes

- Literal colors scattered through the stylesheet, making any theme impossible.
- Components consuming primitive variables instead of semantic ones.
- Defining a variable only inside `@media (prefers-color-scheme: dark)`, so it does not exist in light.
- Dark mode implemented by inverting colors, with pure black and pure white producing glare and halation.
- Forgetting the explicit `body` background.
- No fallback value in contexts where the variable may be missing.
- Names that describe the value (`--blue`) instead of the usage (`--color-accent`).

Next step: [forms.md](forms.md).
