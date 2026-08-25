{ pkgs }:
let
  version = "2.1.241"; # nix-update: version
  hash = "sha256-B3G9hmz/grdlgfwEmfZSnho2hFB48UT4yB3Ms7xwN7g="; # nix-update: hash
in
pkgs.stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  # Official prebuilt binary, straight from Anthropic's own download server
  # (the same URL the official `curl -fsSL https://claude.ai/install.sh`
  # installer uses under the hood).
  src = pkgs.fetchurl {
    url = "https://downloads.claude.ai/claude-code-releases/${version}/linux-x64/claude";
    inherit hash;
  };

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];
  buildInputs = [ pkgs.stdenv.cc.cc.lib ];

  # This is a Bun-compiled standalone executable: the actual JS bundle is
  # appended as trailing data after the ELF image. `strip` would chop that
  # off and leave a binary that runs as a bare `bun` instead of `claude`.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/claude
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Anthropic's official CLI for Claude Code";
    homepage = "https://claude.ai/code";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude";
  };
}
