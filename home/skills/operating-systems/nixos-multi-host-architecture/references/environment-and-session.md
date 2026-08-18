# Environment and Session Layer

## 9. Environment and session layer

Location: `modules/hosts/<scope>/environment/`.

This layer configures the system environment and graphical session.

Recommended structure:

```text
environment/
├── profiles/
└── session/
```

Typical responsibilities:

- locale and environment defaults;
- fonts;
- display managers;
- portals;
- graphical session enablement;
- Sway, GNOME, KDE, or another system-level desktop integration;
- Flatpak policy;
- system-wide session services.

User-specific keybindings, application preferences, and dotfiles belong in
user configuration, not in this layer.
