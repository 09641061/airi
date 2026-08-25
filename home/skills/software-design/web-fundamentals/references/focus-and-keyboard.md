# Focus management and keyboard operation

Keyboard operability is WCAG's *Operable* principle in practice, and the fastest way to find real
accessibility defects: navigate the whole interface with `Tab`, `Shift+Tab`, `Enter`, `Space`, arrows
and `Esc` only.

## The focus indicator

- It must be **visible** and have at least **3:1** contrast against adjacent pixels (WCAG 2.2 criteria
  2.4.7 Focus Visible and 2.4.11 Focus Not Obscured).
- `outline: none` with no replacement is an accessibility failure, not an aesthetic decision.
- Use `:focus-visible` so the ring appears for keyboard navigation but not on mouse clicks.

```css
:focus-visible {
  outline: 3px solid var(--color-brand-focus);
  outline-offset: 3px;
}
```

Give the indicator its own token so it stays contrast-correct in every theme, and check that sticky
headers, overlays and `overflow: hidden` ancestors do not obscure the focused element.

## Tab order

- Tab order follows the visual order. If CSS reordering (`order`, `grid-area`, `flex-direction: row-reverse`)
  breaks that correspondence, fix the DOM order instead.
- A positive `tabindex` is almost always a bug: it hoists the element out of natural order and creates an
  order nobody can maintain. Use only `0` (focusable in order) and `-1` (programmatically focusable, not
  in the tab order).
- Never put `aria-hidden="true"` or `role="presentation"` on a focusable element — the focus lands on a
  node the screen reader cannot describe.

## Skip link

Offer a link to the main content as the first focusable element, visible on focus:

```html
<a href="#main-content" class="skip-link">Skip to main content</a>
```

```css
.skip-link { position: absolute; top: -999px; left: 1rem; z-index: 1000; }
.skip-link:focus { top: 1rem; }
```

## Modals and overlays

1. On open, move focus into the dialog — to the first interactive element, or to the dialog container
   with `tabindex="-1"`.
2. **Trap** focus while it is open: Tab from the last element returns to the first, `Shift+Tab` from the
   first goes to the last.
3. `Esc` closes it.
4. On close, **return** focus to the element that opened it. Losing focus to `<body>` strands keyboard
   and screen-reader users at the top of the document.
5. Content behind the dialog is inert (`inert` attribute, or `aria-hidden` on the background wrapper —
   never on the dialog's own ancestors chain containing focus).

`<dialog>` with `showModal()` provides items 1–3 and the top layer natively — prefer it, and add the
focus return.

## Composite widgets

Menus, tab sets, trees, listboxes and grids use **roving tabindex**: exactly one item in the widget has
`tabindex="0"`, all others `-1`, and arrow keys move both focus and that attribute. `Tab` then enters
and leaves the whole widget as a single stop, which is what users expect. Follow the WAI-ARIA Authoring
Practices keyboard contract for the specific pattern.

## Dynamic content

When content appears without user-initiated focus change (async errors, toast notifications, loaded
results), either move focus to it deliberately or announce it through a live region — see
[accessibility.md](accessibility.md). Silent DOM updates simply do not exist for a screen reader user.

Next step: [audit.md](audit.md).
