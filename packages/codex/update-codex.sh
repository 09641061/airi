#!/usr/bin/env bash
# Asks GitHub for the latest codex release tag, re-downloads the linux
# binary asset to compute its hash, and rewrites ../packages/codex.nix.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

tag=$(gh release view --repo openai/codex --json tagName -q .tagName)
version=${tag#rust-v}
url="https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-unknown-linux-musl.tar.gz"

echo "latest codex: $tag"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

sed -i \
  -e "s|version = \".*\"; # nix-update: version|version = \"${version}\"; # nix-update: version|" \
  -e "s|tag = \".*\"; # nix-update: tag|tag = \"${tag}\"; # nix-update: tag|" \
  -e "s|hash = \".*\"; # nix-update: hash|hash = \"${hash}\"; # nix-update: hash|" \
  default.nix
echo "updated codex.nix -> ${tag}"
