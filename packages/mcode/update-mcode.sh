#!/usr/bin/env bash
# Asks GitHub for the latest minimax-code release, re-downloads the
# npm-package tarball to compute its hash, and rewrites the version/hash
# lines in ../packages/mcode/default.nix in place. Also regenerates the
# vendored package-lock.json from the npm registry if missing/stale.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

tag=$(gh release view --repo MiniMax-AI/minimax-code --json tagName -q .tagName)
version=${tag#v}
url="https://github.com/MiniMax-AI/minimax-code/releases/download/${tag}/minimax-code-${version}.tar.gz"

echo "latest mcode (minimax-code): $tag"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

sed -i \
  -e "s|version = \".*\"; # nix-update: version|version = \"${version}\"; # nix-update: version|" \
  -e "s|hash = \".*\"; # nix-update: hash|hash = \"${hash}\"; # nix-update: hash|" \
  default.nix
echo "updated mcode -> ${tag}"

# Regenerate the vendored package-lock.json against the npm registry if the
# version changed (the upstream tarball ships without one because the
# package is marked `private: true`).
prev_version=$(grep -oE 'version = "[^"]+"' default.nix | head -1 | cut -d'"' -f2)
if [ "$prev_version" != "$version" ] || [ ! -f package-lock.json ]; then
  echo "regenerating vendored package-lock.json for ${tag}"
  tmp=$(mktemp -d)
  curl -sLo "$tmp/src.tgz" "$url"
  tar -xzf "$tmp/src.tgz" -C "$tmp"
  (cd "$tmp/package" && \
    npm install --package-lock-only --ignore-scripts \
                --registry=https://registry.npmjs.org/ \
                --no-audit --no-fund)
  cp "$tmp/package/package-lock.json" package-lock.json
  rm -rf "$tmp"
  echo "vendored package-lock.json"
fi

echo "note: bump npmDepsHash by running \`nix build .#mcode\` once and"
echo "      updating the placeholder with the SRI the error message prints"
