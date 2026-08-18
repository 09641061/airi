# Shared/Host-Specific Modules, Profiles, and Aggregators

## 10. Shared and host-specific modules

Use explicit scope to distinguish reusable modules from machine-specific ones:

```text
modules/hosts/shared/<domain>       reusable capability
modules/hosts/<host>/<domain>       host-specific capability
```

Shared modules must not depend on a particular host name. Host-specific modules
may depend on shared options and capabilities.

Good dependency direction:

```text
Host Composition
      │
      ├── Shared Profiles
      └── Host-Specific Profiles
              │
              └── System Options and Services
```

Avoid copying a shared module just to change one value. Prefer an option with a
safe default, a host override, or a small host-specific module.

## 11. Profiles, aggregators, and module depth

An aggregator module imports smaller modules:

```text
applications/profiles/desktop/default.nix
└── tools/default.nix
    ├── audio.nix
    ├── display.nix
    └── launcher.nix
```

Aggregators are organizational units. They do not create runtime phases.

Keep import depth understandable. Deep nesting is acceptable when each level
has a clear responsibility, but arbitrary chains of `default.nix` files make
ownership and debugging harder.
