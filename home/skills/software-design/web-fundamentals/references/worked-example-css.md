# Worked example: the stylesheet

The CSS for the page in [worked-example.md](worked-example.md): tokens with light/dark, an
accessible base, and BEM components built on Grid and Flexbox.


```css
/* ==========================================================================
   1. CUSTOM PROPERTIES / DESIGN TOKENS
   WCAG 2.2 AA (>= 4.5:1 for normal text). Measured ratios noted inline.
   ========================================================================== */

:root {
  /* Light palette — complete and unconditional */
  --color-bg-body: #f8fafc;
  --color-bg-surface: #ffffff;
  --color-bg-elevated: #f1f5f9;

  --color-text-primary: #0f172a;       /* 15.8:1 on #ffffff */
  --color-text-secondary: #475569;     /* 5.9:1 on #ffffff */
  --color-text-inverse: #ffffff;

  --color-primary: #0284c7;            /* 4.6:1 on #ffffff */
  --color-primary-hover: #0369a1;
  --color-primary-focus: #0284c7;

  --color-badge-bg: #e0f2fe;
  --color-badge-text: #0369a1;         /* 5.1:1 on #e0f2fe */

  --color-elective-bg: #fef3c7;
  --color-elective-text: #92400e;      /* 6.8:1 on #fef3c7 */

  --color-border: #cbd5e1;
  --color-border-focus: #0284c7;
  --color-error: #dc2626;

  --font-family-base: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --font-size-xs: 0.8125rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.75rem;

  --space-xs: 0.5rem;
  --space-sm: 0.75rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
  --space-2xl: 3rem;

  --radius-sm: 0.375rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
}

/* Follow the system preference, unless light was chosen explicitly */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --color-bg-body: #090d16;
    --color-bg-surface: #111827;
    --color-bg-elevated: #1f2937;

    --color-text-primary: #f9fafb;     /* 15.3:1 on #111827 */
    --color-text-secondary: #9ca3af;   /* 5.4:1 on #111827 */
    --color-text-inverse: #090d16;

    --color-primary: #38bdf8;          /* 8.9:1 on #111827 */
    --color-primary-hover: #7dd3fc;
    --color-primary-focus: #38bdf8;

    --color-badge-bg: #075985;
    --color-badge-text: #e0f2fe;       /* 6.2:1 on #075985 */

    --color-elective-bg: #78350f;
    --color-elective-text: #fef3c7;    /* 7.1:1 on #78350f */

    --color-border: #374151;
    --color-border-focus: #38bdf8;
    --color-error: #f87171;
  }
}

/* Explicit toggle wins in both directions */
:root[data-theme="dark"] {
  --color-bg-body: #090d16;
  --color-bg-surface: #111827;
  --color-bg-elevated: #1f2937;
  --color-text-primary: #f9fafb;
  --color-text-secondary: #9ca3af;
  --color-text-inverse: #090d16;
  --color-primary: #38bdf8;
  --color-primary-hover: #7dd3fc;
  --color-primary-focus: #38bdf8;
  --color-badge-bg: #075985;
  --color-badge-text: #e0f2fe;
  --color-elective-bg: #78350f;
  --color-elective-text: #fef3c7;
  --color-border: #374151;
  --color-border-focus: #38bdf8;
  --color-error: #f87171;
}

/* ==========================================================================
   2. RESET AND ACCESSIBLE BASE
   ========================================================================== */

*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: var(--font-family-base);
  font-size: var(--font-size-base);
  line-height: 1.6;
  background-color: var(--color-bg-body);
  color: var(--color-text-primary);
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Universal high-contrast focus indicator (WCAG 2.2 — 2.4.7) */
:focus-visible {
  outline: 3px solid var(--color-primary-focus);
  outline-offset: 3px;
}

.skip-link {
  position: absolute;
  top: -999px;
  left: 1rem;
  background-color: var(--color-primary);
  color: var(--color-text-inverse);
  padding: var(--space-sm) var(--space-md);
  font-weight: 700;
  text-decoration: none;
  border-radius: var(--radius-sm);
  z-index: 1000;
}

.skip-link:focus { top: 1rem; }

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}

/* ==========================================================================
   3. HEADER AND NAVIGATION (BEM + Flexbox)
   ========================================================================== */

.header {
  background-color: var(--color-bg-surface);
  border-bottom: 1px solid var(--color-border);
  position: sticky;
  top: 0;
  z-index: 100;
}

.header__container {
  max-width: 1200px;
  margin: 0 auto;
  padding: var(--space-md) var(--space-lg);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: var(--space-md);
}

.header__brand { display: flex; align-items: center; gap: var(--space-sm); }

.header__logo-badge {
  background-color: var(--color-primary);
  color: var(--color-text-inverse);
  font-weight: 800;
  font-size: var(--font-size-sm);
  padding: 0.25rem 0.5rem;
  border-radius: var(--radius-sm);
  letter-spacing: 0.05em;
}

.header__brand-name {
  font-weight: 700;
  font-size: var(--font-size-lg);
  color: var(--color-text-primary);
}

.nav__list { display: flex; list-style: none; gap: var(--space-md); }

.nav__link {
  color: var(--color-text-secondary);
  text-decoration: none;
  font-weight: 500;
  padding: var(--space-xs) var(--space-sm);
  border-radius: var(--radius-sm);
  transition: color 0.15s ease-in-out;
}

.nav__link:hover { color: var(--color-primary); }

/* Current page marked by state, not by a bespoke class */
.nav__link[aria-current="page"] {
  color: var(--color-primary);
  font-weight: 700;
  border-bottom: 2px solid var(--color-primary);
}

.btn-theme {
  background-color: var(--color-bg-elevated);
  color: var(--color-text-primary);
  border: 1px solid var(--color-border);
  padding: var(--space-xs) var(--space-md);
  border-radius: var(--radius-md);
  cursor: pointer;
  font-weight: 600;
}

/* ==========================================================================
   4. MAIN LAYOUT
   ========================================================================== */

.main-layout {
  flex: 1;
  max-width: 1200px;
  width: 100%;
  margin: 0 auto;
  padding: var(--space-2xl) var(--space-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-2xl);
}

.page-title-block__heading {
  font-size: var(--font-size-2xl);
  font-weight: 800;
  color: var(--color-text-primary);
  margin-bottom: var(--space-xs);
}

.page-title-block__lead {
  font-size: var(--font-size-lg);
  color: var(--color-text-secondary);
}

/* ==========================================================================
   5. COURSES (two-dimensional Grid, no media queries)
   ========================================================================== */

.courses-section__header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: var(--space-lg);
  border-bottom: 1px solid var(--color-border);
  padding-bottom: var(--space-sm);
}

.courses-section__title { font-size: var(--font-size-xl); font-weight: 700; }

.courses-section__count {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
}

.courses-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: var(--space-xl);
}

.course-card {
  background-color: var(--color-bg-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-lg);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-shadow: var(--shadow-sm);
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.course-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.course-card__header { margin-bottom: var(--space-md); }

.course-card__badge {
  display: inline-block;
  font-size: var(--font-size-xs);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 0.2rem 0.5rem;
  border-radius: var(--radius-sm);
  background-color: var(--color-badge-bg);
  color: var(--color-badge-text);
  margin-bottom: var(--space-xs);
}

.course-card__badge--elective {
  background-color: var(--color-elective-bg);
  color: var(--color-elective-text);
}

.course-card__title { font-size: var(--font-size-lg); font-weight: 700; line-height: 1.3; }

.course-card__body {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: var(--space-md);
  margin-bottom: var(--space-lg);
}

.course-card__description {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
}

.course-card__meta {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: var(--space-xs) var(--space-sm);
  font-size: var(--font-size-sm);
}

.course-card__meta-term { font-weight: 600; color: var(--color-text-secondary); }
.course-card__meta-def { color: var(--color-text-primary); }
.course-card__footer { margin-top: auto; }

/* ==========================================================================
   6. BUTTONS (BEM)
   ========================================================================== */

.btn {
  display: inline-block;
  width: 100%;
  text-align: center;
  padding: var(--space-sm) var(--space-md);
  font-size: var(--font-size-sm);
  font-weight: 600;
  text-decoration: none;
  border-radius: var(--radius-md);
  border: 1px solid transparent;
  cursor: pointer;
  transition: background-color 0.15s ease-in-out;
}

.btn--primary { background-color: var(--color-primary); color: var(--color-text-inverse); }
.btn--primary:hover { background-color: var(--color-primary-hover); }

/* ==========================================================================
   7. FORMS
   ========================================================================== */

.request-section {
  background-color: var(--color-bg-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-xl);
  box-shadow: var(--shadow-sm);
}

.request-section__title {
  font-size: var(--font-size-xl);
  font-weight: 700;
  margin-bottom: var(--space-lg);
}

.form { display: flex; flex-direction: column; gap: var(--space-lg); }
.form__group { display: flex; flex-direction: column; gap: var(--space-xs); }

.form__label,
.form__legend {
  font-size: var(--font-size-sm);
  font-weight: 600;
  color: var(--color-text-primary);
}

.form__required { color: var(--color-error); }

.form__input,
.form__textarea {
  width: 100%;
  padding: var(--space-sm) var(--space-md);
  font-family: inherit;
  font-size: var(--font-size-base);
  color: var(--color-text-primary);
  background-color: var(--color-bg-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.form__input:focus,
.form__textarea:focus { border-color: var(--color-border-focus); }

/* Invalid state carries a border AND a text message — never color alone */
.form__input[aria-invalid="true"],
.form__textarea[aria-invalid="true"] { border-color: var(--color-error); }

.form__help { font-size: var(--font-size-xs); color: var(--color-text-secondary); }
.form__error { font-size: var(--font-size-xs); color: var(--color-error); font-weight: 600; }

.form__fieldset {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: var(--space-md) var(--space-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}

.form__choice { display: flex; align-items: center; gap: var(--space-sm); }

.form__radio {
  width: 1.125rem;
  height: 1.125rem;
  accent-color: var(--color-primary);
  cursor: pointer;
}

.form__choice-label {
  font-size: var(--font-size-sm);
  color: var(--color-text-primary);
  cursor: pointer;
}

.form__actions { display: flex; justify-content: flex-end; }
.form__actions .btn { width: auto; min-width: 200px; }

/* ==========================================================================
   8. SIDEBAR AND FOOTER
   ========================================================================== */

.sidebar-info {
  background-color: var(--color-bg-elevated);
  border-top: 1px solid var(--color-border);
  border-bottom: 1px solid var(--color-border);
  padding: var(--space-xl) var(--space-lg);
}

.sidebar-info__container { max-width: 1200px; margin: 0 auto; }

.sidebar-info__title {
  font-size: var(--font-size-lg);
  font-weight: 700;
  margin-bottom: var(--space-md);
}

.sidebar-info__list {
  list-style-type: square;
  padding-left: var(--space-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-xs);
  color: var(--color-text-secondary);
}

.footer {
  background-color: var(--color-bg-surface);
  border-top: 1px solid var(--color-border);
  margin-top: auto;
}

.footer__container {
  max-width: 1200px;
  margin: 0 auto;
  padding: var(--space-xl) var(--space-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-md);
  align-items: center;
  text-align: center;
}

@media (min-width: 768px) {
  .footer__container {
    flex-direction: row;
    justify-content: space-between;
    text-align: left;
  }
}

.footer__copyright { font-size: var(--font-size-xs); color: var(--color-text-secondary); }
.footer__links { list-style: none; display: flex; gap: var(--space-md); }

.footer__link {
  font-size: var(--font-size-xs);
  color: var(--color-text-secondary);
  text-decoration: none;
}

.footer__link:hover { color: var(--color-primary); }
```

