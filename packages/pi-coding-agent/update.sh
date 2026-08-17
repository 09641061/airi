#!/usr/bin/env bash
# Asks GitHub for the latest pi release tag, re-downloads the linux asset
# to compute its hash, and rewrites versions.nix.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

tag=$(gh release view --repo earendil-works/pi --json tagName -q .tagName)
version=${tag#v}
url="https://github.com/earendil-works/pi/releases/download/${tag}/pi-linux-x64.tar.gz"

echo "latest pi: $tag"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

cat > versions.nix <<EOF
{
  version = "${version}";
  hash = "${hash}";
}
EOF
echo "wrote versions.nix -> ${tag}"
