---
name: nixos-multi-host-architecture
description: Design or review a maintainable, scalable, multi-host NixOS configuration using explicit architectural layers — flake composition root, host composition, hardware/boot/filesystem/networking/services/applications/environment domains, shared vs host-specific modules, module options, and the Home Manager boundary. Use whenever asked to structure, scaffold, or review a NixOS flake/repository, add a new host, split a monolithic configuration.nix, or decide where a piece of NixOS configuration belongs.
---

# Layered NixOS Architecture

Independent of a particular repository, host name, desktop environment,
package set, or deployment tool. Separates machine facts, operating-system
capabilities, applications, graphical sessions, and user preferences using
NixOS module composition instead of a single monolithic configuration file.

## Core rules

1. Keep the flake as the composition root and deployment boundary.
2. Keep machine facts separate from reusable operating-system modules.
3. Keep shared modules independent from host-specific details.
4. Organize modules by responsibility, not by arbitrary file size.
5. Prefer small profiles and capabilities over one global package list.
6. Expose configurable behavior through namespaced module options.
7. Pass external dependencies explicitly through module arguments.
8. Keep user configuration separate from system configuration.
9. Home Manager, when used, is for user configuration only. It must not define,
   install, or download packages.
10. Treat directory layers as architectural boundaries, not as runtime order.

## Architectural model

```text
Flake / Composition Root
│
├── Host Composition
│   ├── Machine Facts
│   ├── Shared System Modules
│   └── Host-Specific Modules
│
├── Operating-System Domains
│   ├── Hardware
│   ├── Boot
│   ├── Filesystem
│   ├── Networking
│   ├── Services
│   ├── Applications
│   └── Environment / Session
│
└── User Configuration
    └── Home Manager, if used
```

The domains are orthogonal responsibilities. A configuration may contain all
of them, but they are not required to form a linear stack.

## Build order

Follow this order — load each reference only when you reach that step; don't front-load all of them.

| # | Step | Reference |
|---|------|-----------|
| 1 | Flake and host composition | [references/flake-and-host-composition.md](references/flake-and-host-composition.md) |
| 2 | Hardware and boot/kernel layers | [references/hardware-and-boot.md](references/hardware-and-boot.md) |
| 3 | Filesystem/storage and networking layers | [references/filesystem-and-networking.md](references/filesystem-and-networking.md) |
| 4 | Services and applications/package-profiles layers | [references/services-and-applications.md](references/services-and-applications.md) |
| 5 | Environment and graphical session layer | [references/environment-and-session.md](references/environment-and-session.md) |
| 6 | Shared vs host-specific modules, profiles, aggregators | [references/module-organization.md](references/module-organization.md) |
| 7 | Home Manager boundary (user config, no packages) | [references/home-manager-boundary.md](references/home-manager-boundary.md) |
| 8 | Module options, contracts, dependency injection | [references/options-and-dependency-injection.md](references/options-and-dependency-injection.md) |
| 9 | Evaluation vs runtime, implementation order, validation checklist | [references/evaluation-and-checklist.md](references/evaluation-and-checklist.md) |

## Source of truth

The original, unsplit guide (kept for traceability) lives at:
`operating-systems/multi-host-nixos-architecture.md`.
