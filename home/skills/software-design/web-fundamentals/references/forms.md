# Forms: labelling, input types, validation

The form is where accessibility and usability break most often and with the worst consequences: it is
where the user hands over data, and where a defect stops them completing the task.

## Labelling

- **Every input needs an associated `<label>`**, with `for` matching the control's `id`, or wrapping it.
  That association is what makes the screen reader announce the field and what makes clicking the label
  focus the control.
- **A `placeholder` is not a label.** It disappears on typing, has insufficient contrast by default, and
  is not announced consistently by assistive technology. Use it only as a format example, in addition to
  the label.
- Group related controls (radio groups, checkbox sets) in `<fieldset>` with `<legend>`. The legend is
  what gives each option its context; without it every radio is announced contextless.
- Link help text with `aria-describedby`.

## Types and attributes

Use the right `type` (`email`, `tel`, `url`, `number`, `date`): it selects the correct mobile keyboard
and enables native browser validation.

Add `autocomplete` with the standard token (`given-name`, `email`, `street-address`, `one-time-code`).
It is a large usability win and a direct aid to users with motor impairments.

Mark mandatory fields with `required` **and** a textual visual indication — not just a colored asterisk.
Native constraint attributes (`required`, `pattern`, `minlength`, `min`/`max`) do work the browser would
otherwise duplicate in JavaScript.

## Validation

- **Timing**: validate on **blur**, not on every keystroke. Validating while typing flags an email as
  invalid before the user has finished writing it.
- **Permissive rules**: accept spaces, dashes and varied formats in phone numbers and card numbers, and
  normalise them yourself. Rejecting correct data on formatting grounds is the most irritating form defect.
- **On submit**: move focus to the first field in error, or to an error summary whose entries link to
  each field.
- **Never color alone**: each error carries `aria-invalid="true"`, a text message wired with
  `aria-describedby`, and a visual indication that does not depend on hue.
- The message **names the problem and the way out**: *The date must be later than today*, not
  *Invalid field*.
- Errors that appear dynamically need a live region (`aria-live="polite"`) or the focus, otherwise the
  screen reader never announces them.

## Shape of an accessible field

```html
<div class="form__group">
  <label for="student-email" class="form__label">
    Institutional email <span class="form__required" aria-hidden="true">*</span>
  </label>
  <input
    type="email"
    id="student-email"
    name="email"
    class="form__input"
    required
    autocomplete="email"
    aria-describedby="email-help email-error"
    aria-invalid="true"
    placeholder="name@university.edu">
  <p id="email-help" class="form__help">Must belong to the university domain.</p>
  <p id="email-error" class="form__error" aria-live="polite">Enter an address ending in @university.edu.</p>
</div>
```

Remove `aria-invalid` and the error node when the field becomes valid — a stale invalid state is worse
than none.

## Focus styling for controls

Never remove the outline without a visible, high-contrast replacement. `:focus-visible` applies focus
styling only for keyboard navigation, avoiding unwanted rings on mouse clicks:

```css
:focus-visible {
  outline: 3px solid var(--color-brand-focus);
  outline-offset: 2px;
}
```

## Common mistakes

- `placeholder` as the only label.
- Errors conveyed by a red border alone.
- Validation on every keypress.
- Rejecting phone or card numbers containing spaces or dashes.
- Radio groups with no `fieldset`/`legend`.
- Submitting without moving focus, leaving the user unaware of what happened.
- Disabled fields with no explanation of what would enable them.
- Missing `autocomplete`, forcing users to retype data the browser already had.

Mobile-specific form behaviour: [mobile-design](../../mobile-design/references/forms-and-input.md).
Next step: [accessibility.md](accessibility.md).
