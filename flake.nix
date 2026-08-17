{
  description = "airi — CLI agents (claude-code, codex, antigravity-cli, pi-coding-agent), each packaged as its own Nix derivation that fetches the prebuilt binary directly from the tool's official source (Anthropic, and GitHub releases for OpenAI, Google, and earendil-works) instead of relying on nixpkgs' copy of them.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # claude-code / antigravity-cli / pi are closed-source
      };

      claude-code = import ./packages/claude-code { inherit pkgs; };
      codex = import ./packages/codex { inherit pkgs; };
      antigravity-cli = import ./packages/antigravity-cli { inherit pkgs; };
      pi-coding-agent = import ./packages/pi-coding-agent { inherit pkgs; };

      mkUpdateApp = name: {
        type = "app";
        program = toString (
          pkgs.writeShellScript "update-${name}" ''
            exec bash ${self}/packages/${name}/update.sh "$@"
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
          ;

        # Install all four at once if you want.
        default = pkgs.symlinkJoin {
          name = "airi-tools";
          paths = [
            claude-code
            codex
            antigravity-cli
            pi-coding-agent
          ];
        };
      };

      # Per-tool updaters: pull the latest official release, recompute the
      # hash, and rewrite packages/<tool>/versions.nix.
      #   nix run .#update-claude-code
      #   nix run .#update-codex
      #   nix run .#update-pi-coding-agent
      #   nix run .#update-antigravity-cli -- 1.1.14-6068529322131456
      apps.${system} = {
        update-claude-code = mkUpdateApp "claude-code";
        update-codex = mkUpdateApp "codex";
        update-pi-coding-agent = mkUpdateApp "pi-coding-agent";
        update-antigravity-cli = mkUpdateApp "antigravity-cli";
      };
    };
}
