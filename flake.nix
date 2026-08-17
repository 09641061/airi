{
  description = "flare — CLI agents (claude-code, codex, antigravity-cli, pi-coding-agent) packaged individually, each pinned to its own nixpkgs revision so they can be updated one at a time.";

  inputs = {
    # Base nixpkgs, used only for `lib` helpers (genAttrs, etc). Doesn't need
    # to carry any of the actual packages.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # One nixpkgs input PER TOOL. They all start out pointing at the same
    # branch, but each gets its own entry in flake.lock, so you can bump
    # just one of them without touching (or rebuilding) the others:
    #
    #   nix flake lock --update-input nixpkgs-codex
    #
    # This is what makes each tool "downloadable/updatable separately"
    # while still being fully reproducible (every input is pinned by hash).
    nixpkgs-claude-code.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-codex.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-antigravity.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-pi.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-claude-code,
      nixpkgs-codex,
      nixpkgs-antigravity,
      nixpkgs-pi,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      pkgsFor =
        input: system:
        import input {
          inherit system;
          config.allowUnfree = true; # antigravity-cli is marked unfree
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          claude-code = import ./packages/claude-code { pkgs = pkgsFor nixpkgs-claude-code system; };
          codex = import ./packages/codex { pkgs = pkgsFor nixpkgs-codex system; };
          antigravity-cli = import ./packages/antigravity-cli { pkgs = pkgsFor nixpkgs-antigravity system; };
          pi-coding-agent = import ./packages/pi-coding-agent { pkgs = pkgsFor nixpkgs-pi system; };
          pkgs = pkgsFor nixpkgs system;
        in
        {
          inherit
            claude-code
            codex
            antigravity-cli
            pi-coding-agent
            ;

          # Install all four at once if you want.
          default = pkgs.symlinkJoin {
            name = "flare-tools";
            paths = [
              claude-code
              codex
              antigravity-cli
              pi-coding-agent
            ];
          };
        }
      );
    };
}
