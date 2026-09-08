{ pkgs }:
let
  version = "0.9.0"; # nix-update: version
  hash = "sha256-T6GgEVjdgEPaktMbJweAsNzBBgMDjZthysTYGrY/tx8="; # nix-update: hash
in
pkgs.stdenv.mkDerivation {
  pname = "herdr";
  inherit version;

  # Official prebuilt Linux binary from Herdr's GitHub release.
  src = pkgs.fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-x86_64";
    inherit hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/herdr
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Terminal workspace manager for coding agents";
    homepage = "https://herdr.dev";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "herdr";
  };
}
