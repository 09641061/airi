{ pkgs }:
let
  version = "1.1.27"; # nix-update: version
  hash = "sha256-+HTU9rinPC32YPWA8l+2Vvy25krb/XRuZpLoN/2aIL4="; # nix-update: hash
in
pkgs.stdenv.mkDerivation {
  pname = "antigravity-cli";
  inherit version;

  # Official prebuilt binary from Google's GitHub releases
  # (github.com/google-antigravity/antigravity-cli/releases).
  src = pkgs.fetchurl {
    url = "https://github.com/google-antigravity/antigravity-cli/releases/download/${version}/agy_cli_linux_x64.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  unpackPhase = ''
    runHook preUnpack
    tar xzf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/bin/antigravity
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Google's official Antigravity CLI";
    homepage = "https://github.com/google-antigravity/antigravity-cli";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "antigravity";
  };
}
