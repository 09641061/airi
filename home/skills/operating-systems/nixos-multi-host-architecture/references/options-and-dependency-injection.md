# Options, Module Contracts, and Dependency Injection

## 13. Options and module contracts

Configurable capabilities should expose namespaced options and keep their
implementation behind those options:

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.platform.services.example;
in
{
  options.platform.services.example.enable =
    lib.mkEnableOption "the example service";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.example ];
    systemd.services.example = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.example}/bin/example";
    };
  };
}
```

Use `lib.mkDefault` for overridable defaults, `lib.mkIf` for conditional
configuration, `lib.mkMerge` for intentional composition, and `lib.mkForce`
only when a higher-priority value is required.

## 14. Dependency injection

Pass values explicitly through module arguments:

- `specialArgs` for NixOS modules;
- `extraSpecialArgs` for Home Manager modules.

Use injected arguments for stable external dependencies such as host identity,
roles, platform helpers, or flake-provided packages. Do not rely on hidden
imports or global mutable state.
