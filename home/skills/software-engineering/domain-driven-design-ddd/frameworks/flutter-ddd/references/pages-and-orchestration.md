# Frontend Controllers (Page Orchestrators)

Location: `[context-name]/interfaces/rest/transform/` and `[context-name]/interfaces/pages/`

In frontend, controllers are route-level orchestrators (smart pages/facades) that coordinate commands/queries and UI state.

- **Naming Convention:** Files end with `Screen`, `Controller`, or `Notifier`.
- **Orchestration:** Trigger command/query services based on UI actions.
- **State Handling:** Manage loading, success, empty, and error states — prefer consuming an `AsyncValue<T>` from a Riverpod provider and pattern-matching it (`.when`/`switch`) over manual boolean flags.
- **Routing:** Screens are registered as `go_router` routes with typed route params/extras; the screen widget maps them into a query, it does not parse raw path segments itself.
- **Transformation:** Convert `Resource <-> Command/Query` with pure transform functions.

-  File names follow orchestrator convention
-  Route params/query params mapped into queries via typed `go_router` routes
-  Proper UI state handling via `AsyncValue` (loading/error/success/empty)
-  Input validation with Form widgets
-  Resource-to-command/query transformation
-  Domain/result-to-resource transformation
