# Flake and Host Composition

## 1. Flake and composition root

Location: repository root, normally `flake.nix`.

The flake defines system inputs, reusable functions, overlays, modules, and
deployable configurations. It is responsible for composition, not for holding
all host details.

Responsibilities:

- declare and pin inputs;
- define supported system architectures;
- construct one system configuration per host;
- provide shared `specialArgs`;
- register overlays and reusable outputs;
- connect NixOS and optional Home Manager modules.

The flake should answer: "Which complete systems can be built or deployed?"
It should not answer every machine-specific configuration question.

## 2. Host composition layer

Location: `hosts/<host-name>/`.

The host directory is the composition boundary for one physical or logical
machine. Its entry module imports the capabilities required by that host.

Recommended contents:

```text
hosts/<host-name>/
├── default.nix
├── hardware-configuration.nix
├── disk.nix                    # when storage is host-specific
└── secrets/                     # when encrypted host secrets are used
```

The host composition should contain:

- hardware facts;
- disk and filesystem facts;
- host name and machine identity;
- selected roles and profiles;
- host-specific overrides;
- imports of shared and host-specific modules.

The host composition should not contain the implementation of every service,
application, or subsystem it enables.

Checklist:

- [ ] Host-specific facts are isolated here.
- [ ] Shared capabilities are imported instead of duplicated.
- [ ] Host-specific behavior is explicitly selected.
- [ ] Secrets are scoped to the appropriate host.
- [ ] The file remains a composition root rather than a monolith.
