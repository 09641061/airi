{ pkgs }:
let
  version = "0.5.5"; # nix-update: version
  hash = "sha256-hKgbEiN7DGJpHvUAZ/qvq4HgoTjaGTbR/uRsXyc/N0I="; # nix-update: hash
in
pkgs.buildNpmPackage {
  pname = "minimax-code";
  inherit version;

  # The upstream release tarball wraps the source tree under a
  # package/ directory; the wrapper derivation flattens it so
  # package.json sits at the root and adds the vendored lockfile
  # next to it. Without the lockfile buildNpmPackage would not be
  # able to make npmDepsHash reproducible — see update-minimax-code.sh
  # for the regeneration step on version bumps.
  src = pkgs.stdenv.mkDerivation {
    pname = "minimax-code-source";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/MiniMax-AI/minimax-code/releases/download/v${version}/minimax-code-${version}.tar.gz";
      inherit hash;
    };

    dontConfigure = true;
    dontBuild = true;

    # The tarball auto-sets sourceRoot to package/, so we are already
    # inside it. autoPatchelfHook is unnecessary here (no ELF binaries
    # at this stage), but makeWrapper will be needed downstream.
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r ./. $out/
      chmod -R u+w $out
      cp ${./package-lock.json} $out/package-lock.json
      runHook postInstall
    '';
  };

  # Hash of the resolved npm dependency tree, captured by running the
  # build once with lib.fakeSha256 and reading the actual value from
  # the 'hash mismatch' error.
  npmDepsHash = "sha256-shyiNqHRYIYDFPyrgs0qVGfXPLzqlFlVp7PKmGCoXhE="; # nix-update: npmDepsHash

  # better-sqlite3 is a native optional dependency that ships prebuilt
  # binaries via node-gyp; pull it in so the agent can persist sessions.
  npmFlags = [ "--include=optional" ];

  # Required for the better-sqlite3 node-gyp build inside the sandbox.
  nativeBuildInputs = [
    pkgs.python3
    pkgs.gcc
  ];

  # The upstream package ships prebundled JS chunks; there is no build
  # script. The postinstall (verify-native-install.mjs) still runs and
  # asserts the sqlite native binding is loadable, which is what we want.
  dontNpmBuild = true;

  meta = with pkgs.lib; {
    description = "MiniMax Code — terminal coding agent powered by MiniMax";
    longDescription = ''
      Open-source coding agent for your terminal, powered by MiniMax.
      Supports the official MiniMax API, third-party OpenAI/Anthropic-compatible
      providers, plugin skills, and a TUI for interactive sessions.
    '';
    homepage = "https://github.com/MiniMax-AI/minimax-code";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "mcode";
  };
}
