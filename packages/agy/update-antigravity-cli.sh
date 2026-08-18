#!/usr/bin/env bash
# Asks GitHub for the latest antigravity-cli release tag, re-downloads the
# linux asset to compute its hash, and rewrites
# ../packages/antigravity-cli.nix in place.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

version=$(gh release view --repo google-antigravity/antigravity-cli --json tagName -q .tagName)
url="https://github.com/google-antigravity/antigravity-cli/releases/download/${version}/agy_cli_linux_x64.tar.gz"

echo "latest antigravity-cli: $version"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

sed -i \
  -e "s|version = \".*\"; # nix-update: version|version = \"${version}\"; # nix-update: version|" \
  -e "s|hash = \".*\"; # nix-update: hash|hash = \"${hash}\"; # nix-update: hash|" \
  default.nix
echo "updated antigravity-cli.nix -> ${version}"
