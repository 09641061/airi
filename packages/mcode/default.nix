{ pkgs }:
let
  version = "0.6.5"; # nix-update: version
  tag = "v${version}"; # nix-update: tag
  hash = "sha256-Fjd66S1uHAdS6gp5HrXchZWEyjHQwf5n1kPINP7anwI="; # nix-update: hash

  # Vendored `package-lock.json` — the upstream tarball ships without one
  # (the package is marked `private: true`), but `buildNpmPackage` insists
  # on a lockfile to pin transitive deps. Regenerate with:
  #   tar xzf minimax-code-${version}.tar.gz
  #   cd package
  #   npm install --package-lock-only --ignore-scripts \
  #               --registry=https://registry.npmjs.org/
  packageLock = ./package-lock.json;

  # Combine the upstream tarball with the vendored lockfile so
  # `buildNpmPackage` can resolve `node_modules` bit-for-bit.
  srcWithLock = pkgs.runCommand "mcode-${version}-src-with-lock" { } ''
    mkdir -p "$out"
    tar -xzf ${pkgs.fetchurl {
      url = "https://github.com/MiniMax-AI/minimax-code/releases/download/${tag}/minimax-code-${version}.tar.gz";
      inherit hash;
    }} --strip-components=1 -C "$out"
    cp ${packageLock} "$out/package-lock.json"
  '';
in
pkgs.buildNpmPackage {
  pname = "mcode";
  inherit version;

  src = srcWithLock;

  # The tarball already contains the precompiled `chunks/*.js` bundle, so
  # skip the package's own `npm run build` step (the package is also
  # `private: true` and declares no `scripts.build`).
  dontNpmBuild = true;

  # Allow better-sqlite3's postinstall to run so its native binding is
  # compiled against the runtime Node ABI. `buildNpmPackage`'s
  # `npmDepsHash` still pins the resolved dependency tree against the
  # registry so the bit-identical module graph is reproduced.
  npmFlags = [ "--ignore-scripts=false" ];

  # Hash of the fully-resolved `node_modules` tree.
  # Placeholder — populated by the first build attempt.
  npmDepsHash = "sha256-sf4ES4WBV3OJ/xp9KHMfT7rn7e9XSIwg00ME26E96E8=";

  nativeBuildInputs = [
    pkgs.python3
    pkgs.pkg-config
    pkgs.makeWrapper
  ];

  buildInputs = [
    pkgs.stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/mcode $out/bin
    # The `buildPhase` of buildNpmPackage leaves the unpacked tree (incl.
    # `node_modules`) in `$PWD`. `package/` (the upstream layout) is the
    # real source root — move its contents into $out/lib/mcode.
    if [ -d package ]; then
      mv package/* $out/lib/mcode/
      rmdir package
    else
      cp -r . $out/lib/mcode/
    fi
    chmod -R u+w $out/lib/mcode
    # `bin` from package.json points at `cli.js` (a Node script). Wrap it
    # so callers don't need a Node on PATH.
    makeWrapper ${pkgs.lib.getExe pkgs.nodejs} $out/bin/mcode \
      --add-flags "$out/lib/mcode/cli.js" \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs ]}
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "MiniMax Code CLI — open-source terminal coding agent, invoked as `mcode`";
    homepage = "https://github.com/MiniMax-AI/minimax-code";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "mcode";
  };
}
