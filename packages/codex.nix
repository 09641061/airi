{ pkgs }:
let
  version = "0.147.0"; # nix-update: version
  tag = "rust-v0.147.0"; # nix-update: tag
  hash = "sha256-Akbi53ODTgfw+1JJ7W660S5FkeYI+Me7l91qlpBUTDY="; # nix-update: hash
in
pkgs.stdenv.mkDerivation {
  pname = "codex";
  inherit version;

  # Official prebuilt binary from OpenAI's GitHub release for this tag
  # (github.com/openai/codex/releases) — no build from source, no npm.
  src = pkgs.fetchurl {
    url = "https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-unknown-linux-musl.tar.gz";
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
    install -Dm755 codex-x86_64-unknown-linux-musl $out/bin/codex
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "OpenAI's official Codex CLI coding agent";
    homepage = "https://github.com/openai/codex";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
