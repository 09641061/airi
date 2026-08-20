{
  description = "airi — CLI agents (claude-code, codex, antigravity-cli, pi-coding-agent, herdr), each packaged as its own Nix derivation that fetches the prebuilt binary directly from the tool's official source.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pi.url = "github:lukasl-dev/pi.nix";
  };

  outputs =
    { self, nixpkgs, pi, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # claude-code / antigravity-cli / pi are closed-source
      };

      claude-code = import ./packages/claude { inherit pkgs; };
      codex = import ./packages/codex { inherit pkgs; };
      antigravity-cli = import ./packages/agy { inherit pkgs; };
      pi-coding-agent = import ./packages/pi { inherit pkgs; };
      herdr = import ./packages/herdr { inherit pkgs; };

      mkUpdateApp = name: {
        type = "app";
        program = toString (
          pkgs.writeShellScript "update-${name}" ''
            exec bash ${
              if name == "claude-code" then "${self}/packages/claude/update-claude-code.sh"
              else if name == "codex" then "${self}/packages/codex/update-codex.sh"
              else if name == "pi-coding-agent" then "${self}/packages/pi/update-pi-coding-agent.sh"
              else if name == "herdr" then "${self}/packages/herdr/update-herdr.sh"
              else "${self}/packages/agy/update-antigravity-cli.sh"
            } "$@"
          ''
        );
      };
    in
    {
      packages.${system} = {
        inherit
          claude-code
          codex
          antigravity-cli
          pi-coding-agent
          herdr
          ;

        # Install all tools at once if you want.
        default = pkgs.symlinkJoin {
          name = "airi-tools";
          paths = [
            claude-code
            codex
            antigravity-cli
            pi-coding-agent
            herdr
          ];
        };
      };

      homeModules.ai = { ... }@args:
        import ./home-module.nix (args // { inherit pi; });

      # Per-tool updaters: pull the latest official release, recompute the
      # hash, and rewrite the version/hash lines in packages/<tool>.nix.
      #   nix run .#update-claude-code
      #   nix run .#update-codex
      #   nix run .#update-pi-coding-agent
      #   nix run .#update-herdr
      #   nix run .#update-antigravity-cli -- 1.1.14-6068529322131456
      apps.${system} = {
        update-claude-code = mkUpdateApp "claude-code";
        update-codex = mkUpdateApp "codex";
        update-pi-coding-agent = mkUpdateApp "pi-coding-agent";
        update-herdr = mkUpdateApp "herdr";
        update-antigravity-cli = mkUpdateApp "antigravity-cli";
      };
    };
}
