# Worked example: an academic portal page

A complete page applying every step in order: strict semantic HTML5, WAI-ARIA 1.2, WCAG 2.2 AA
contrast, custom properties with light/dark theming, and BEM CSS built on Grid and Flexbox.

## `index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Software Engineering academic portal: courses, enrolment and accessible academic resources.">
  <title>Academic Portal | Software Engineering</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <!-- Skip link: first focusable element -->
  <a href="#main-content" class="skip-link">Skip to main content</a>

  <!-- Global landmark: banner -->
  <header class="header">
    <div class="header__container">
      <div class="header__brand">
        <span class="header__logo-badge" aria-hidden="true">SE</span>
        <span class="header__brand-name">Software Engineering Portal</span>
      </div>

      <nav class="nav" aria-label="Primary">
        <ul class="nav__list">
          <li class="nav__item"><a href="#courses" class="nav__link" aria-current="page">My courses</a></li>
          <li class="nav__item"><a href="#enrolment" class="nav__link">Enrolment</a></li>
          <li class="nav__item"><a href="#resources" class="nav__link">Resources</a></li>
        </ul>
      </nav>

      <div class="header__actions">
        <button type="button" class="btn-theme" id="btn-toggle-theme" aria-label="Toggle dark or light theme">
          <span class="btn-theme__text" aria-hidden="true">Theme</span>
        </button>
      </div>
    </div>
  </header>

  <!-- Single main landmark -->
  <main id="main-content" class="main-layout">

    <header class="page-title-block">
      <h1 class="page-title-block__heading">Academic dashboard 2026-02</h1>
      <p class="page-title-block__lead">
        Manage your active subjects and engineering projects.
      </p>
    </header>

    <section class="courses-section" aria-labelledby="courses-section-title">
      <div class="courses-section__header">
        <h2 id="courses-section-title" class="courses-section__title">Enrolled courses</h2>
        <span class="courses-section__count" aria-live="polite">Total: 3 subjects</span>
      </div>

      <div class="courses-grid">

        <article class="course-card" aria-labelledby="course-1-title">
          <header class="course-card__header">
            <span class="course-card__badge">Required</span>
            <h3 id="course-1-title" class="course-card__title">SI385: Frontend Web Technologies</h3>
          </header>
          <div class="course-card__body">
            <p class="course-card__description">
              Accessible interface development, semantic HTML5, modern CSS and scalable architectures.
            </p>
            <dl class="course-card__meta">
              <dt class="course-card__meta-term">Instructor:</dt>
              <dd class="course-card__meta-def">M. Alva</dd>
              <dt class="course-card__meta-term">Credits:</dt>
              <dd class="course-card__meta-def">4.0</dd>
            </dl>
          </div>
          <footer class="course-card__footer">
            <a href="#classroom-si385" class="btn btn--primary" aria-label="Enter the SI385 Frontend Web Technologies virtual classroom">
              Enter classroom
            </a>
          </footer>
        </article>

        <article class="course-card" aria-labelledby="course-2-title">
          <header class="course-card__header">
            <span class="course-card__badge">Required</span>
            <h3 id="course-2-title" class="course-card__title">SI650: Software Architecture Design</h3>
          </header>
          <div class="course-card__body">
            <p class="course-card__description">
              Architectural patterns, microservices, domain-driven design and distributed systems.
            </p>
            <dl class="course-card__meta">
              <dt class="course-card__meta-term">Instructor:</dt>
              <dd class="course-card__meta-def">C. Ramos</dd>
              <dt class="course-card__meta-term">Credits:</dt>
              <dd class="course-card__meta-def">5.0</dd>
            </dl>
          </div>
          <footer class="course-card__footer">
            <a href="#classroom-si650" class="btn btn--primary" aria-label="Enter the SI650 Software Architecture Design virtual classroom">
              Enter classroom
            </a>
          </footer>
        </article>

        <article class="course-card" aria-labelledby="course-3-title">
          <header class="course-card__header">
            <span class="course-card__badge course-card__badge--elective">Elective</span>
            <h3 id="course-3-title" class="course-card__title">SI720: Web Security and Cryptography</h3>
          </header>
          <div class="course-card__body">
            <p class="course-card__description">
              Cryptographic protocols, OWASP Top 10, strong authentication and identity management.
            </p>
            <dl class="course-card__meta">
              <dt class="course-card__meta-term">Instructor:</dt>
              <dd class="course-card__meta-def">R. Vega</dd>
              <dt class="course-card__meta-term">Credits:</dt>
              <dd class="course-card__meta-def">3.0</dd>
            </dl>
          </div>
          <footer class="course-card__footer">
            <a href="#classroom-si720" class="btn btn--primary" aria-label="Enter the SI720 Web Security and Cryptography virtual classroom">
              Enter classroom
            </a>
          </footer>
        </article>

      </div>
    </section>

    <section class="request-section" aria-labelledby="request-section-title">
      <h2 id="request-section-title" class="request-section__title">Submit an academic request</h2>

      <form class="form" id="request-form" novalidate>

        <div class="form__group">
          <label for="field-student" class="form__label">
            Student name <span class="form__required" aria-hidden="true">*</span>
          </label>
          <input
            type="text"
            id="field-student"
            name="student"
            class="form__input"
            required
            aria-describedby="help-student"
            autocomplete="name">
          <p id="help-student" class="form__help">Enter your full legal name as it appears on your enrolment record.</p>
          <p id="error-student" class="form__error" aria-live="polite" hidden>The student name is required.</p>
        </div>

        <div class="form__group">
          <label for="field-email" class="form__label">
            Institutional email <span class="form__required" aria-hidden="true">*</span>
          </label>
          <input
            type="email"
            id="field-email"
            name="email"
            class="form__input"
            required
            aria-describedby="help-email"
            autocomplete="email"
            placeholder="name@university.edu">
          <p id="help-email" class="form__help">Must belong to the @university.edu domain.</p>
        </div>

        <fieldset class="form__fieldset">
          <legend class="form__legend">Request type <span class="form__required" aria-hidden="true">*</span></legend>

          <div class="form__choice">
            <input type="radio" id="type-absence" name="request_type" value="absence" class="form__radio" required checked>
            <label for="type-absence" class="form__choice-label">Absence or assessment justification</label>
          </div>

          <div class="form__choice">
            <input type="radio" id="type-correction" name="request_type" value="correction" class="form__radio">
            <label for="type-correction" class="form__choice-label">Enrolment correction</label>
          </div>

          <div class="form__choice">
            <input type="radio" id="type-tutoring" name="request_type" value="tutoring" class="form__radio">
            <label for="type-tutoring" class="form__choice-label">Specialised tutoring request</label>
          </div>
        </fieldset>

        <div class="form__group">
          <label for="field-reason" class="form__label">
            Supporting details <span class="form__required" aria-hidden="true">*</span>
          </label>
          <textarea
            id="field-reason"
            name="reason"
            rows="4"
            class="form__textarea"
            required
            aria-describedby="help-reason"></textarea>
          <p id="help-reason" class="form__help">Clearly explain the academic or medical grounds for your request.</p>
        </div>

        <div class="form__actions">
          <button type="submit" class="btn btn--primary">Submit request</button>
        </div>

      </form>
    </section>

  </main>

  <!-- complementary landmark -->
  <aside class="sidebar-info" aria-labelledby="notices-title">
    <div class="sidebar-info__container">
      <h2 id="notices-title" class="sidebar-info__title">Coordination notices</h2>
      <ul class="sidebar-info__list">
        <li class="sidebar-info__item">
          <strong>TB1 submission deadline:</strong> Sunday 31 August, 23:59.
        </li>
        <li class="sidebar-info__item">
          <strong>Virtual classroom maintenance:</strong> Saturday 30 August, 02:00–05:00.
        </li>
      </ul>
    </div>
  </aside>

  <!-- contentinfo landmark -->
  <footer class="footer">
    <div class="footer__container">
      <p class="footer__copyright">
        &copy; 2026 School of Software Engineering.
      </p>
      <nav class="footer__nav" aria-label="Legal and privacy">
        <ul class="footer__links">
          <li><a href="#privacy" class="footer__link">Privacy policy</a></li>
          <li><a href="#terms" class="footer__link">Terms of use</a></li>
          <li><a href="#accessibility" class="footer__link">Accessibility statement</a></li>
        </ul>
      </nav>
    </div>
  </footer>
</body>
</html>
```

## What to notice

- The `<aside>` sits outside `<main>` — complementary content is not part of the main content.
- Every `<section>` is named with `aria-labelledby` pointing at its own heading, so it becomes a
  navigable region.
- Icon-only and ambiguous links carry a specific `aria-label`; the decorative logo badge is
  `aria-hidden="true"`.
- The current nav item is styled from `[aria-current="page"]`, so state and presentation cannot drift.
- Every color, size and spacing value comes from a token; the light and dark palettes are both complete.

The stylesheet for this page: [worked-example-css.md](worked-example-css.md).
