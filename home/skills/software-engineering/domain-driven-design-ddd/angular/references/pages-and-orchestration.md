# Frontend Controllers (Page Orchestrators)

Location: `[context-name]/interfaces/rest/transform/` and `[context-name]/interfaces/pages/`

In frontend, controllers are route-level orchestrators (smart pages/facades) that coordinate commands/queries and UI state.

- **Naming Convention:** Files end with `PageComponent` or `Controller` (if your frontend convention uses that suffix).
- **Standalone:** Page components are standalone; route to them directly via lazy-loaded functional routes (`loadComponent`), no `NgModule` wiring.
- **Orchestration:** Trigger command/query services based on UI actions.
- **State Handling:** Manage loading, success, empty, and error states as **signals** (`signal`/`computed`) rather than manually-managed subject streams; derive `isLoading`/`isEmpty`/`hasError` with `computed()`.
- **Transformation:** Convert `Resource <-> Command/Query` with pure transform functions.
- **Templates:** Use `@if`/`@for`/`@switch` control flow blocks, not `*ngIf`/`*ngFor`.

- [ ] File names follow orchestrator convention
- [ ] Component is standalone and lazy-loaded via `loadComponent`
- [ ] Route params/query params mapped into queries
- [ ] Proper UI state handling (loading/error/success/empty) via signals
- [ ] Input validation with Angular forms
- [ ] Resource-to-command/query transformation
- [ ] Domain/result-to-resource transformation
- [ ] Templates use `@if`/`@for`/`@switch`, not structural directives
