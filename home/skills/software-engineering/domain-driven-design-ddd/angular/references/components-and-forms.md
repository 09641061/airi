# Components and Forms Management

Location: `[context-name]/interfaces/components/` and `[context-name]/interfaces/pages/`

Components and forms must follow clear separation of concerns.

- **Presentational vs Orchestrator:**
  - Presentational components render UI and emit events, using signal-based `input()`/`output()` instead of the `@Input()`/`@Output()` decorators.
  - Page/orchestrator components coordinate use cases (commands/queries).
- **Reactive Forms First:** Use `FormGroup`, `FormControl`, and validators for form state; where the project has adopted **Signal Forms**, model form state with `form()`/signal-backed fields instead, keeping the same validation and submit-transform rules below.
- **Button Behavior:** Buttons trigger user intent only (`save`, `delete`, `search`); they do not call HTTP directly.
- **Command Binding:** On submit, transform `form value -> Command` using explicit transform functions.
- **UI States:** Always implement `loading`, `success`, `error`, and `empty` states, modeled as signals/computed values, not manual booleans mutated ad hoc.
- **Validation UX:** Show touched/dirty errors and disable submit when invalid.
- **Change Detection:** Components must be compatible with zoneless change detection — avoid patterns that rely on `Zone.js` picking up mutations implicitly (e.g., mutating plain objects/arrays in place); prefer signals or immutable updates.

- [ ] Form components are split from page orchestration when complexity requires
- [ ] Reactive Forms (or Signal Forms, if adopted) used for create/edit flows
- [ ] `input()`/`output()` signal APIs used instead of `@Input()`/`@Output()` decorators
- [ ] Submit handlers transform values into commands
- [ ] Buttons trigger handlers, not direct API calls
- [ ] Validation messages and disabled submit behavior implemented
- [ ] Loading/error/success/empty states handled consistently as signals
- [ ] Edit form supports patching existing values safely
- [ ] No implicit Zone.js-dependent mutation patterns
