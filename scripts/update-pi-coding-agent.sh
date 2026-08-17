#!/usr/bin/env bash
# Asks GitHub for the latest pi release tag, re-downloads the linux asset
# to compute its hash, and rewrites ../packages/pi-coding-agent.nix.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../packages"

tag=$(gh release view --repo earendil-works/pi --json tagName -q .tagName)
version=${tag#v}
url="https://github.com/earendil-works/pi/releases/download/${tag}/pi-linux-x64.tar.gz"

echo "latest pi: $tag"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

sed -i \
  -e "s|version = \".*\"; # nix-update: version|version = \"${version}\"; # nix-update: version|" \
  -e "s|hash = \".*\"; # nix-update: hash|hash = \"${hash}\"; # nix-update: hash|" \
  pi-coding-agent.nix
echo "updated pi-coding-agent.nix -> ${tag}"
