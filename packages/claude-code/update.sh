#!/usr/bin/env bash
# Checks npm for the latest published claude-code version, re-downloads it
# from Anthropic's official server to compute its hash, and rewrites
# versions.nix. Run from anywhere; run `nix flake check` afterwards.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

latest=$(curl -sf https://registry.npmjs.org/@anthropic-ai/claude-code/latest | python3 -c 'import json,sys;print(json.load(sys.stdin)["version"])')
url="https://downloads.claude.ai/claude-code-releases/${latest}/linux-x64/claude"

echo "latest claude-code: $latest"
base32=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --to sri "$base32")

cat > versions.nix <<EOF
{
  version = "${latest}";
  hash = "${hash}";
}
EOF
echo "wrote versions.nix -> ${latest}"
