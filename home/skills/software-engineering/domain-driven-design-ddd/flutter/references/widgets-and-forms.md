# Widgets and Forms Management

Location: `[context-name]/interfaces/widgets/` and `[context-name]/interfaces/pages/`

Widgets and forms must follow clear separation of concerns.

- **Presentational vs Orchestrator**
  - Presentational widgets render UI and emit callbacks.
  - Screen/orchestrator widgets coordinate use cases.
- **Forms First:** Use `Form`, `GlobalKey<FormState>`, validators.
- **Button Behavior:** Buttons trigger user intent only (`save`, `delete`, `search`); they do not call HTTP directly.
- **Command Binding:** On submit, transform `form value -> Command` using explicit transform functions.
- **UI States:** Always implement `loading`, `success`, `error`, and `empty` states, driven by `AsyncValue`/`ConsumerWidget` rebuilds rather than `setState` for anything backed by a provider.
- **Validation UX:** Show validation errors and disable submit when invalid.
- **Widget Choice:** Prefer `ConsumerWidget`/`HookConsumerWidget` over `StatefulWidget` for widgets that read providers; reserve `StatefulWidget` for purely local, non-domain UI state (animation controllers, scroll offsets).

-  Form widgets are split from page orchestration when complexity requires
-  Form widgets used for create/edit flows
-  Submit handlers transform values into commands
-  Buttons trigger handlers, not direct API calls
-  Validation messages and disabled submit behavior implemented
-  Loading/error/success/empty states handled consistently via `AsyncValue`
-  Edit forms support patching existing values safely
-  `ConsumerWidget`/`HookConsumerWidget` used instead of `StatefulWidget` where providers are read
