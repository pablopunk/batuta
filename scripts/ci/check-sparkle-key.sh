#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT/scripts/release-settings.sh"

: "${SPARKLE_PRIVATE_KEY_FILE:?}"
ZIP_PATH="${1:-$ROOT/dist/Batuta.zip}"
ED25519_PRIVATE_KEY_DER_PREFIX="302e020100300506032b657004220420"

public_key_of_sparkle_private_key_file() {
  { printf '%s' "$ED25519_PRIVATE_KEY_DER_PREFIX" | xxd -r -p
    base64 --decode < "$SPARKLE_PRIVATE_KEY_FILE" | head -c 32
  } | openssl pkey -inform DER -pubout -outform DER | tail -c 32 | base64
}

if [[ "$(public_key_of_sparkle_private_key_file)" != "$SPARKLE_PUBLIC_ED_KEY" ]]; then
  echo "SPARKLE_PRIVATE_KEY does not match SPARKLE_PUBLIC_ED_KEY; installed apps would reject the update." >&2
  exit 1
fi

"$SPARKLE_BIN_DIR/sign_update" --ed-key-file "$SPARKLE_PRIVATE_KEY_FILE" -p "$ZIP_PATH" >/dev/null
echo "Sparkle key matches the app and signs $(basename "$ZIP_PATH")."
