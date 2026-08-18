# Services and Applications Layers

## 7. Services layer

Location: `modules/hosts/<scope>/system/services/`.

The services layer manages long-running system processes and daemons.

Typical responsibilities:

- service enablement and configuration;
- systemd units and dependencies;
- Docker or other virtualization services;
- databases;
- SSH servers;
- web servers and reverse proxies;
- PipeWire, printing, keyrings, and scheduled daemons.

Keep a service's required package next to its service module when the package
has no meaning outside that service.

Service modules should expose clear options instead of requiring hosts to
modify internal implementation details.

## 8. Applications and package profiles layer

Location: `modules/hosts/<scope>/applications/`.

This layer makes system applications and tools available. It should use small,
purpose-driven profiles rather than one indiscriminate package list.

Recommended structure:

```text
applications/
├── overlays/
└── profiles/
    ├── desktop/
    ├── development/
    ├── languages/
    ├── media/
    └── tools/
```

Typical responsibilities:

- command-line tools;
- browsers and desktop applications;
- development toolchains;
- language runtimes and language servers;
- media tools;
- role-specific utilities.

System packages should be declared through NixOS options such as
`environment.systemPackages`, `fonts.packages`, or the package option of the
system service that owns the package.

Avoid a global list containing every package for every host. Prefer profiles
that can be composed by role.
