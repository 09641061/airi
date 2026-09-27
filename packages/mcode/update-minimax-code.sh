#!/usr/bin/env bash
# Asks GitHub for the latest MiniMax Code release tag, re-downloads the
# source tarball to compute its hash, regenerates package-lock.json
# against the public npm registry, and rewrites ../packages/mcode.nix.
#
# After running this, do `nix build .#minimax-code` once with
# `npmDepsHash = lib.fakeSha256` to capture the new dependency hash
# (look for the 'got: sha256-...' line in the error) and paste it back.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

version=$(gh release view --repo MiniMax-AI/minimax-code --json tagName -q .tagName | sed 's/^v//')
url="https://github.com/MiniMax-AI/minimax-code/releases/download/v${version}/minimax-code-${version}.tar.gz"

echo "latest minimax-code: v${version}"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

# Regenerate the lockfile from the upstream tarball so the dependency
# tree stays reproducible on every version bump.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -sfL -o "$tmp/src.tar.gz" "$url"
tar xzf "$tmp/src.tar.gz" -C "$tmp"
(
  cd "$tmp/package"
  npm install --package-lock-only --ignore-scripts --include=optional \
    --no-audit --no-fund --registry=https://registry.npmjs.org/ >/dev/null
)
mv "$tmp/package/package-lock.json" ./package-lock.json

sed -i \
  -e "s|version = \".*\"; # nix-update: version|version = \"${version}\"; # nix-update: version|" \
  -e "s|hash = \".*\"; # nix-update: hash|hash = \"${hash}\"; # nix-update: hash|" \
  default.nix

echo "updated minimax-code.nix -> v${version}"
echo "updated package-lock.json (run \`nix build .#minimax-code\` with"
echo "  npmDepsHash = lib.fakeSha256 to capture the new hash, then paste"
echo "  the 'got: sha256-...' value into default.nix)."
