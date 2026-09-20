# UI Layer

[Skill overview and workflow](../SKILL.md). Examples target Next.js 16 and React 19.3; verify project versions.

## UI Layer

Keep UI code in `interfaces/`. Presentational components render view models and raise interaction callbacks; they do not call Application services or instantiate adapters. Server orchestration components can call composed services, but should remain distinct from presentation. Keep React state minimal: derive values during render rather than synchronizing them with effects, and avoid automatic `useState(props...)` copies; an intentional editable draft needs an explicit reset/reconciliation policy. Put persistent, shareable filters and pagination in the URL when appropriate. Hooks encapsulate React behavior and lifecycle, not ordinary pure transforms. Rendering must stay pure: never mutate props, cached data, or shared objects, and use immutable state updates. Extract components by responsibility (SRP), reuse, and interaction boundaries, not a rigid line-count threshold. Apply DRY to stable shared behavior without building flag-driven mega-forms. Prefer cohesive ports (ISP) and injected adapters over centralized provider switches. Place helpers beside the behavior they serve with meaningful names, rather than accumulating generic `utils/` modules.

Use pure transform functions when crossing a real semantic boundary: provider resource to application model, application model to view model, or validated form input to command. Avoid a separate DTO/resource/mapper class for every layer when all shapes mean the same thing. Classes remain useful for entities with identity and behavior; the goal is to remove ceremony, not prohibit classes universally.

Apply SOLID pragmatically: SRP by responsibility, DIP through consumer-owned ports at genuine IO boundaries, ISP through small contracts, and OCP through injected provider implementations when variation exists. Do not invent inheritance hierarchies to demonstrate LSP; where substitution exists, implementations must preserve their contract.

Optional review heuristic: around 150 lines, inspect cohesion; around 200, look for separable responsibilities; around 300, review orchestration and duplication carefully. These are prompts, not lint rules or rigid limits; a cohesive file can remain larger.
