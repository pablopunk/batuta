#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts/release-settings.sh"

[[ -x "$SPARKLE_BIN_DIR/generate_keys" ]] || swift package resolve

echo "Generating Sparkle EdDSA keys (the private key stays in your login keychain)..."
"$SPARKLE_BIN_DIR/generate_keys" "$@"
echo "Paste the public key into SPARKLE_PUBLIC_ED_KEY in scripts/release-settings.sh."
