{ pkgs }:
let
  version = "0.148.0"; # nix-update: version
  tag = "rust-v0.148.0"; # nix-update: tag
  hash = "sha256-jHkFAK8rpudM5JSP4mxlGsH3f227AFtHyNJv9xEUYmI="; # nix-update: hash
in
pkgs.stdenv.mkDerivation {
  pname = "codex";
  inherit version;

  # Official prebuilt binary from OpenAI's GitHub release for this tag
  # (github.com/openai/codex/releases) — no build from source, no npm.
  src = pkgs.fetchurl {
    # The package archive includes codex, codex-code-mode-host, bwrap,
    # ripgrep, and the other runtime resources required by Code Mode.
    url = "https://github.com/openai/codex/releases/download/${tag}/codex-package-x86_64-unknown-linux-musl.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];
  buildInputs = [ pkgs.ncurses ];

  unpackPhase = ''
    runHook preUnpack
    tar xzf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    # Keep the upstream package layout: the CLI resolves the host and
    # runtime resources relative to these directories.
    install -Dm755 bin/codex $out/bin/codex
    install -Dm755 bin/codex-code-mode-host $out/bin/codex-code-mode-host
    cp -r codex-resources $out/codex-resources
    cp -r codex-path $out/codex-path
    install -Dm644 codex-package.json $out/codex-package.json
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
