# Evaluation/Runtime, Implementation Order, and Validation Checklist

## 15. Evaluation and runtime

Nix evaluates and merges modules before building the system. Imports describe
composition and visibility; they do not define boot order.

Runtime ordering belongs to systemd and is expressed with:

- `wantedBy`;
- `after`;
- `before`;
- `requires`;
- `wants`;
- service conditions and targets.

Keep evaluation-time composition separate from runtime orchestration.

## 16. Recommended implementation order

1. Define the flake inputs and system boundaries.
2. Create the host composition modules.
3. Record hardware and filesystem facts.
4. Add boot and kernel policy.
5. Add networking policy.
6. Add reusable system defaults.
7. Add services and their options.
8. Add application and development profiles.
9. Add environment and session integration.
10. Add optional Home Manager user configuration.
11. Validate each host independently.
12. Review package ownership and module boundaries.

## 17. Validation checklist

- [ ] The flake is the composition root.
- [ ] Each host has an explicit composition module.
- [ ] Machine facts are separate from reusable modules.
- [ ] Hardware, boot, storage, networking, services, applications, and
      environment concerns have clear ownership.
- [ ] Shared modules contain no host-specific assumptions.
- [ ] Host-specific behavior is selected explicitly.
- [ ] Packages are declared in NixOS, never in Home Manager.
- [ ] Home Manager contains user configuration only.
- [ ] Module options use clear namespaces.
- [ ] Imports are understandable and not needlessly deep.
- [ ] Runtime dependencies are expressed through systemd.
- [ ] Secrets are encrypted and scoped appropriately.

## Final architecture

```text
Flake
└── Host Composition
    ├── Machine Facts
    ├── Shared Modules
    │   ├── hardware
    │   ├── boot
    │   ├── filesystem
    │   ├── networking
    │   ├── services
    │   ├── applications
    │   └── environment
    ├── Host-Specific Modules
    └── Home Manager
        └── user configuration only; no package management
```
