#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts/release-settings.sh"

APP_NAME="Batuta"
CONFIGURATION="${CONFIGURATION:-release}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$ROOT/dist}"
APP_PATH="$ROOT/.build/$CONFIGURATION/$APP_NAME.app"
ZIP_PATH="$ARTIFACTS_DIR/$APP_NAME.zip"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
NOTARY_PROFILE="${NOTARY_PROFILE:-$DEFAULT_NOTARY_KEYCHAIN_PROFILE}"
NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-$NOTARY_PROFILE}"
SKIP_NOTARIZE="${SKIP_NOTARIZE:-0}"

INSTALL_APP=0 CONFIGURATION="$CONFIGURATION" CODESIGN_IDENTITY="$CODESIGN_IDENTITY" "$ROOT/scripts/build-app.sh"

rm -rf "$ARTIFACTS_DIR"
mkdir -p "$ARTIFACTS_DIR"

zip_release() {
  rm -f "$ZIP_PATH"
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
}

should_notarize() {
  [[ "$SKIP_NOTARIZE" != "1" && "$CODESIGN_IDENTITY" != "-" && -n "$NOTARY_KEYCHAIN_PROFILE" ]]
}

zip_release

if should_notarize; then
  echo "Submitting for notarization with profile: $NOTARY_KEYCHAIN_PROFILE"
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
  xcrun stapler staple "$APP_PATH"
  zip_release
fi

shasum -a 256 "$ZIP_PATH" | awk '{print $1}' > "$ZIP_PATH.sha256"

echo "Created $ZIP_PATH"
echo "SHA256 $(cat "$ZIP_PATH.sha256")"
