#!/usr/bin/env bash
# Update Herdr to the latest Linux x86_64 GitHub release and refresh its hash.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

tag=$(gh release view --repo herdrdev/herdr --json tagName -q .tagName)
version=${tag#v}
url="https://github.com/herdrdev/herdr/releases/download/${tag}/herdr-linux-x86_64"

echo "latest herdr: $tag"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

sed -i \
  -e "s|version = \".*\"; # nix-update: version|version = \"${version}\"; # nix-update: version|" \
  -e "s|hash = \".*\"; # nix-update: hash|hash = \"${hash}\"; # nix-update: hash|" \
  default.nix

echo "updated Herdr -> ${tag}"
