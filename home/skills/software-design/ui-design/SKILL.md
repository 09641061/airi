---
name: ui-design
description: Standard process for creating or improving professional application UI. Use when building or redesigning UI screens, choosing components/icons, or reviewing UI for consistency and generic-AI-look issues.
metadata:
  type: process-guide
---

# UI Design Implementation Guide

This guide defines the standard process for creating or improving professional application UI.

The objective is to produce beautiful, consistent, compact, accessible interfaces that feel intentionally designed and never like generic AI-generated UI.

1. **Never assume the language or framework. Inspect the project first.**
2. **Use the project's existing language, framework, conventions, and file types.**
3. **Use shadcn-compatible components as the UI primitive standard whenever supported by the current stack.**
4. **Use the appropriate Lucide package for the current framework as the standard icon system.**
5. **Reuse existing shared components before creating new components.**
6. **Centralize colors, spacing, typography, radius, states, and other visual decisions through the existing design system/tokens.**
7. **Do not redesign application screens as landing pages.**

---

### 1. Project and UI Analysis

Before writing code, inspect:

* current framework and language
* styling system
* existing UI library
* shared/common components
* design tokens/theme
* layouts and navigation
* existing pages implementing similar patterns

Use the syntax and patterns already established by the project. Do not convert JavaScript to TypeScript, JSX to TSX, Vue to React, or change frameworks only for UI purposes.

Before creating anything, search:

```text
existing feature
→ shared/common components
→ existing UI primitives
→ shadcn implementation
→ new component
```

* [ ] Current stack identified
* [ ] Existing shared UI inspected
* [ ] Existing design system inspected
* [ ] No unnecessary stack changes

---

### 2. Skills and Research

Before designing important UI, consult the relevant available skills.

Recommended:

```text
frontend-design
→ visual direction and avoiding generic AI UI

ui-design-brain
→ choose appropriate UI/component patterns

shadcn
→ components, composition and primitives

design-system-patterns
→ tokens and scalable visual systems

tailwind-design-system
→ when the project uses Tailwind

web-design-guidelines
→ usability, interaction and accessibility review

critique
→ identify visual/design problems

distill
→ remove unnecessary UI

quieter
→ reduce excessive visual noise

polish
→ final refinement

vercel-composition-patterns
→ when the project uses React

find-skills
→ discover a more appropriate framework-specific skill when necessary
```

Do not invoke every skill blindly. Select those relevant to the current task and stack.

If the correct design pattern is unclear, research real production web applications and official component documentation before implementing.

Prefer:

```text
real SaaS applications
professional dashboards
productivity applications
official design systems
official framework documentation
```

over random AI designs, Dribbble concepts, or landing-page inspiration.

---

### 3. Design System Standard

UI should be composed from the project's centralized system.

Prefer:

```text
Design Tokens
      ↓
UI Primitives / shadcn
      ↓
Shared Application Components
      ↓
Feature Components
      ↓
Pages
```

Centralize:

* colors
* typography
* spacing
* radius
* borders
* shadows
* states
* responsive behavior

Avoid arbitrary values when an existing semantic token exists.

Do not create alternative primitives such as custom buttons, dialogs, inputs, selects, cards, or menus when the existing UI system already provides them.

* [ ] Tokens reused
* [ ] Existing primitives reused
* [ ] Shared patterns reused
* [ ] No duplicate design systems

---

### 4. Lucide Icons

Use Lucide consistently through the package appropriate for the current framework.

Before choosing an icon:

1. Determine its semantic meaning.
2. Search Lucide for that meaning.
3. Compare the available icons.
4. Choose the clearest conventional metaphor.
5. Reuse the same icon for the same action everywhere.

Examples:

```text
create      → Plus
edit        → Pencil
delete      → Trash
search      → Search
settings    → Settings
calendar    → Calendar
users/team  → Users
more        → Ellipsis
```

Do not mix Lucide with random SVGs, emojis, Font Awesome, Heroicons, or other libraries unless the project explicitly requires it.

Icons should support comprehension, not decorate every label.

* [ ] Correct Lucide package used
* [ ] Icons searched by meaning
* [ ] Icon sizes consistent
* [ ] Icon-only controls accessible
* [ ] No unnecessary decorative icons

---

### 5. Application UI Rules

Design for **real applications**, not marketing pages.

Prefer:

```text
App Shell
Sidebar / Navigation
Page Header
Toolbar / Filters
Main Content
Tables / Lists / Forms / Details
```

For structured collections prefer **tables or lists** instead of turning every record into a card.

Use Cards only for genuinely independent contained information.

Avoid by default:

* gradients
* glassmorphism
* giant headings
* hero sections
* excessive rounded corners
* excessive shadows
* oversized spacing
* decorative backgrounds
* colored cards everywhere
* icons everywhere
* every section inside a Card
* excessive badges
* unnecessary animation

Hierarchy should come primarily from:

```text
layout
→ spacing
→ typography
→ contrast
→ color
→ decoration
```

Keep interfaces compact but readable.

Use progressive disclosure for secondary actions through menus, dialogs, sheets, popovers, tabs, or equivalent components provided by the current stack.

---

### 6. UI Review

After implementation, review the result using appropriate skills such as:

```text
web-design-guidelines
→ correctness

critique
→ identify problems

distill
→ remove unnecessary elements

quieter
→ reduce visual noise

polish
→ final refinement
```

Verify:

* [ ] Clear visual hierarchy
* [ ] Consistent spacing
* [ ] Consistent typography
* [ ] Consistent radius and colors
* [ ] shadcn/shared components reused
* [ ] Lucide icons consistent
* [ ] No unnecessary cards
* [ ] No generic AI aesthetics
* [ ] Loading state
* [ ] Empty state
* [ ] Error state
* [ ] Hover/focus/disabled states
* [ ] Responsive behavior
* [ ] Keyboard accessibility
* [ ] No unnecessary dependencies

---

### 7. Implementation Order

Follow this process for every significant UI task:

```text
1. Inspect project and detect stack
2. Inspect existing UI and shared components
3. Consult relevant skills
4. Research real UI patterns if necessary
5. Define hierarchy and interaction
6. Check existing shadcn/UI primitives
7. Search and select Lucide icons
8. Implement using the existing language/framework
9. Reuse or improve shared components
10. Review responsive and accessibility behavior
11. Critique and simplify
12. Polish final UI
```

**Core principle:** every new UI element must justify its existence. If a Card, icon, border, shadow, background, badge, wrapper, animation, or abstraction does not improve usability, hierarchy, comprehension, or consistency, remove it.
