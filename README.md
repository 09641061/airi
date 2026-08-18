# airi

Flake packaging four AI coding CLIs — `claude-code`, `codex`, `antigravity-cli`,
`pi-coding-agent` — each pinned to its own `nixpkgs` input, so each can be
updated independently while staying fully reproducible.

All four already ship in `nixpkgs`; this flake just re-exports them, one
input per tool.

## Layout

```
flake.nix
packages/
  claude/default.nix
  codex/default.nix
  agy/default.nix
  pi/default.nix
```

## Tools

| package | binary | nixpkgs attr | notes |
|---|---|---|---|
| claude-code | `claude` | `claude-code` | |
| codex | `codex` | `codex` | |
| antigravity-cli | `agy` | `antigravity-cli` | unfree, `allowUnfree` already set |
| pi-coding-agent | `pi` | `pi-coding-agent` | |

## Build

```sh
nix build .#claude-code
nix build .#codex
nix build .#antigravity-cli
nix build .#pi-coding-agent
nix build .#default   # all four via symlinkJoin
```

## Update one tool

```sh
nix flake lock --update-input nixpkgs-codex
```

Moves only `codex` to the current `nixos-unstable`, leaving the other three
untouched. If a release hasn't reached `nixos-unstable` yet, point that
input at `github:NixOS/nixpkgs/master` in `flake.nix` instead, then relock.

## Update everything

```sh
nix flake update
```

## Use from a NixOS config

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    airi.url = "path:/home/giks/projects/airi"; # or github:you/airi
  };

  outputs = { nixpkgs, airi, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            airi.packages.${pkgs.system}.claude-code
            airi.packages.${pkgs.system}.codex
          ];
        })
      ];
    };
  };
}
```

Then update `airi` in the system flake and rebuild:

```sh
nix flake lock --update-input airi
sudo nixos-rebuild switch --flake .#host
```

> Do not `follows` the per-tool inputs (`nixpkgs-claude-code`, etc.) onto your
> system's `nixpkgs`. That would make them move together again, defeating the
> point of updating tools one at a time.
