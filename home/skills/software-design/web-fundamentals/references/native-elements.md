# Native elements instead of reinvented ones

Before writing a component, check whether the browser already ships it. A native element arrives with
focus behaviour, keyboard activation, state exposure to the accessibility tree, platform conventions
(context menu, open-in-new-tab, form participation) and years of edge-case handling you will not
reproduce.

## The elements you should not reimplement

| Element | What you get for free | What reimplementing costs you |
| :--- | :--- | :--- |
| `<button>` | Focusable, activates on Enter and Space, `button` role, form submit/reset participation, disabled state | Manual `tabindex`, two key handlers, role, disabled semantics |
| `<a href>` | Navigation, middle-click and modifier-click, context menu, link role, visited state | All of it, badly |
| `<details>` / `<summary>` | Progressive disclosure with zero JavaScript, expanded state exposed | Toggle script, `aria-expanded`, `aria-controls`, animation edge cases |
| `<dialog>` | Modal semantics, top layer, focus containment, `Esc` to close, backdrop | Focus trap, scroll lock, return focus, `aria-modal` |
| `<select>`, `<input type="date">`, `<input type="color">` | Platform pickers, mobile keyboards, native validation | An entire widget with full ARIA authoring-practices keyboard support |
| `<table>` + `<caption>` + `<thead>` + `<th scope>` | Row/column relationships announced during navigation | Grid role plumbing that rarely survives review |
| `<ul>` / `<ol>` | Item count announced ("list, 5 items") | Nothing gained by using divs |
| `<progress>`, `<meter>`, `<output>` | Value semantics exposed as name/role/value | Manual `role` plus `aria-valuenow`/`valuemin`/`valuemax` |

## The decision

- **Action in the page** → `<button type="button">` (or `type="submit"` inside a form).
- **Change of URL / resource** → `<a href="…">`.

An `<a>` with no `href` is not focusable. A `<div onclick>` receives no focus, ignores Enter and Space,
and announces no role. These are the two most common markup defects in production code.

## When ARIA is legitimate

ARIA exists for widgets with no native equivalent: combobox, tree, tab set, carousel, complex grids.
Reach for it only after confirming nothing native covers the case, and then implement the full keyboard
contract from the WAI-ARIA Authoring Practices — roles alone, without keyboard support, make the
component worse than the div it replaced.

The five ARIA rules, condensed:

1. Use a native HTML element with the required semantics and behaviour if one exists.
2. Do not override native semantics unless strictly necessary (avoid `<h2 role="button">`).
3. Every interactive ARIA control must be operable by keyboard (`Tab`, `Enter`, `Space`, arrows).
4. Never put `role="presentation"` or `aria-hidden="true"` on a focusable element.
5. Every interactive element must have a computable accessible name.

Details on roles, states and properties: [accessibility.md](accessibility.md).
Next step: [css-layout.md](css-layout.md).
