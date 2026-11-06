{ pkgs }:

let
  version = "2026.11.05-86047df"; # nix-update: version
  # Official Cursor Agent CLI tarball (same as https://cursor.com/install uses)
  src = pkgs.fetchurl {
    url = "https://downloads.cursor.com/lab/${version}/linux/x64/agent-cli-package.tar.gz";
    hash = "sha256-PLACEHOLDER="; # nix-update: hash
  };
in
pkgs.stdenv.mkDerivation {
  pname = "cursor-cli";
  inherit version;

  inherit src;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    # The tarball usually contains a binary called "cursor" or "agent"
    if [ -f $out/bin/cursor ]; then
      chmod +x $out/bin/cursor
    elif [ -f $out/bin/agent ]; then
      mv $out/bin/agent $out/bin/cursor
      chmod +x $out/bin/cursor
    fi
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Cursor Agent CLI (official)";
    homepage = "https://cursor.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cursor";
  };
}
