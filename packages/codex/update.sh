#!/usr/bin/env bash
# Asks GitHub for the latest codex release tag, re-downloads the linux
# binary asset to compute its hash, and rewrites versions.nix.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

tag=$(gh release view --repo openai/codex --json tagName -q .tagName)
version=${tag#rust-v}
url="https://github.com/openai/codex/releases/download/${tag}/codex-x86_64-unknown-linux-musl.tar.gz"

echo "latest codex: $tag"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

cat > versions.nix <<EOF
{
  version = "${version}";
  tag = "${tag}";
  hash = "${hash}";
}
EOF
echo "wrote versions.nix -> ${tag}"
