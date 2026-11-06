#!/usr/bin/env bash
# Cursor CLI updater for airi
#
# The Cursor Agent CLI is distributed from downloads.cursor.com with build-specific paths.
# There is no clean "latest" URL or GitHub release.
#
# To update:
#   1. Find the latest build at: https://cursor.com (or inspect the official install script)
#   2. Update the version and hash in packages/cursor/default.nix
#
# Example:
#   DOWNLOAD_URL="https://downloads.cursor.com/lab/<build>/linux/x64/agent-cli-package.tar.gz"
#   nix-prefetch-url "$DOWNLOAD_URL"

set -euo pipefail

echo "Cursor CLI packaging in airi uses a manual update process."
echo ""
echo "Current approach:"
echo "  - Edit packages/cursor/default.nix"
echo "  - Update 'version' and the fetchurl 'hash'"
echo ""
echo "To compute a new hash:"
echo "  nix store prefetch-file --hash-type sha256 \\"
echo "    'https://downloads.cursor.com/lab/<build>/linux/x64/agent-cli-package.tar.gz'"
echo ""
echo "Alternatively, run the official installer:"
echo "  curl -fsSL https://cursor.com/install | bash"
exit 0
