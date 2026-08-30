{ pkgs }:
let
  version = "0.84.4"; # nix-update: version
  hash = "sha256-wvPD5qGFC9h2VMw8qIEQEycjl8PQQqTipkxD7htCOXI="; # nix-update: hash
in
pkgs.stdenv.mkDerivation {
  pname = "pi-coding-agent";
  inherit version;

  # Official prebuilt release tarball from earendil-works/pi's own GitHub
  # releases page.
  src = pkgs.fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-x64.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.makeWrapper
  ];
  buildInputs = [ pkgs.stdenv.cc.cc.lib ];

  # Bun-compiled standalone executable — see the comment in
  # packages/claude-code.nix for why stripping breaks it.
  dontStrip = true;

  sourceRoot = "pi";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/pi $out/bin
    cp -r . $out/lib/pi/
    makeWrapper $out/lib/pi/pi $out/bin/pi
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "pi — official coding agent CLI from earendil-works";
    homepage = "https://github.com/earendil-works/pi";
    license = licenses.unfree; # check upstream LICENSE before redistributing
    platforms = [ "x86_64-linux" ];
    mainProgram = "pi";
  };
}
