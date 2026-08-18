#!/usr/bin/env bash
# Checks npm for the latest published claude-code version, re-downloads it
# from Anthropic's official server to compute its hash, and rewrites the
# version/hash lines in ../packages/claude-code.nix in place.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

latest=$(curl -sf https://registry.npmjs.org/@anthropic-ai/claude-code/latest | python3 -c 'import json,sys;print(json.load(sys.stdin)["version"])')
url="https://downloads.claude.ai/claude-code-releases/${latest}/linux-x64/claude"

echo "latest claude-code: $latest"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

sed -i \
  -e "s|version = \".*\"; # nix-update: version|version = \"${latest}\"; # nix-update: version|" \
  -e "s|hash = \".*\"; # nix-update: hash|hash = \"${hash}\"; # nix-update: hash|" \
  default.nix
echo "updated claude-code.nix -> ${latest}"
