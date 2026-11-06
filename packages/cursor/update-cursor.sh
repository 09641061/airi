#!/usr/bin/env bash
# Cursor update helper for airi
#
# Cursor does not publish clean GitHub releases like the other tools.
# The AppImage URL contains a build hash that changes.
#
# Recommended way to update:
#   1. Go to https://cursor.com/download and download the latest Linux AppImage
#   2. Run: nix store prefetch-file --hash-type sha256 /path/to/Cursor-*.AppImage
#   3. Update version + hash + URL in packages/cursor/default.nix
#
# This script exists mainly as a placeholder so `nix run .#update-cursor` works.

set -euo pipefail

echo "Cursor packaging in airi uses a manual update process."
echo ""
echo "Steps to update Cursor:"
echo "  1. Download the latest AppImage from https://cursor.com/download"
echo "  2. Compute the SRI hash:"
echo "     nix store prefetch-file --hash-type sha256 /path/to/Cursor-*.AppImage"
echo "  3. Edit packages/cursor/default.nix with the new version, URL and hash"
echo ""
echo "Alternatively, you can use the official nixpkgs package 'code-cursor'"
echo "if you don't need the airi-managed version."
exit 0
