---
name: web-fundamentals
description: Build web interfaces on a correct markup, CSS and accessibility substrate — semantic HTML5 landmarks, heading hierarchy, native elements over reinvented ones, box model, Flexbox and Grid layout, CSS architecture (BEM, ITCSS, utility-first), theming with custom properties and light/dark, accessible forms with labelling and validation, and WAI-ARIA / WCAG 2.2 roles, states, focus management and audit. Use whenever writing or reviewing HTML or CSS, when markup is a pile of nested divs, when heading levels are picked for font size, when deciding between Flexbox and Grid, when specificity conflicts break styles, when hard-coded colors block theming, when a form announces errors only visually, when a modal loses focus, or when auditing accessibility.
---

# Web Fundamentals: Semantic Markup, CSS and Accessibility

Meaning lives in the markup, not in class names. The browser derives both the render tree and the **accessibility tree** from your HTML; everything screen readers, search engines, reader mode and automation consume comes from that second tree. Accessibility is not a pass at the end — it is a property of the structure you write first.

This skill is the substrate: markup, CSS mechanics, and a11y. Visual craft — typography, color choice, component aesthetics, design systems — lives in the sibling skills [ui-design](../ui-design/SKILL.md), [frontend-design](../frontend-design/SKILL.md), [design-system-patterns](../design-system-patterns/SKILL.md) and [tailwind-design-system](../tailwind-design-system/SKILL.md).

## Core rules

1. Use the element that means the thing. A `<div>` with `onclick` is never acceptable when `<button>` exists.
2. First rule of ARIA: if a native element does the job, use it. Never add a role a native element already exposes.
3. One `<main>` and one `<h1>` per document. Never skip heading levels — size is CSS's job.
4. Set `box-sizing: border-box` globally and declare `lang` on `<html>`. Non-negotiable first lines.
5. Grid for page layout, Flexbox for components. Use `gap`, not margins between siblings.
6. Components consume **semantic** custom properties only, never primitives. No literal colors outside the token layer.
7. Every input has an associated `<label>`. A `placeholder` is never a label.
8. Never remove the focus indicator. `:focus-visible` with >= 3:1 contrast, always.
9. Never convey state or error by color alone — pair it with text and with `aria-invalid` / `aria-describedby`.
10. Automated tools catch roughly a third of accessibility defects. Test with the keyboard and a screen reader before claiming done.

## Build order

This is the order in which a page is actually built — each step's decisions constrain the next. Load the matching reference file only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Landmarks and document structure; heading hierarchy | [references/document-structure.md](references/document-structure.md) |
| 2 | Native elements instead of reinvented ones | [references/native-elements.md](references/native-elements.md) |
| 3 | Layout: box model, Flexbox vs Grid, CSS architecture | [references/css-layout.md](references/css-layout.md) |
| 4 | Theming: custom properties, semantic layers, light/dark | [references/theming.md](references/theming.md) |
| 5 | Forms: labelling, input types, validation, errors | [references/forms.md](references/forms.md) |
| 6 | Accessibility pass: POUR, accessibility tree, ARIA roles/states | [references/accessibility.md](references/accessibility.md) |
| 7 | Focus management and keyboard operation | [references/focus-and-keyboard.md](references/focus-and-keyboard.md) |
| 8 | Audit before shipping | [references/audit.md](references/audit.md) |

A full worked page is in [references/worked-example.md](references/worked-example.md) (semantic HTML) and [references/worked-example-css.md](references/worked-example-css.md) (tokenized, themed, BEM CSS).

## Common mistakes

- Divitis: `<div class="header">` instead of `<header>`, so the accessibility tree exposes no landmarks to jump between.
- Heading levels chosen for font size; multiple or nested `<main>`; `<section>` used as a generic box with no heading.
- `role="button"` on a div, with no keyboard handling and no focus — or redundant ARIA on elements that already expose the role.
- `outline: none` with no replacement; modals that neither trap nor return focus; positive `tabindex`.
- Fighting widths because `box-sizing` was never set; Grid used for a single row; Flexbox used for a two-axis layout.
- Specificity escalation ending in `!important`; absolute positioning used as a layout system; fixed widths and heights that break with real content.
- Literal colors scattered through the stylesheet; a variable defined only inside `@media (prefers-color-scheme: dark)`; transparent `body` background.
- Dark mode built by inverting colors, with pure black and pure white producing glare and halation.
- `placeholder` as the only label; validation firing on every keystroke; phone numbers rejected for containing spaces; submit that never moves focus.
- Decorative images with redundant `alt` text, informative images with `alt=""`.
