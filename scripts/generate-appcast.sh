#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts/release-settings.sh"

APP_NAME="Batuta"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
ZIP_PATH="${1:-$ROOT/dist/$APP_NAME.zip}"
APPCAST_PATH="$ROOT/appcast.xml"
DOWNLOAD_URL_PREFIX="https://github.com/$BATUTA_GITHUB_REPOSITORY/releases/download/v$VERSION/"
SPARKLE_PRIVATE_KEY_FILE="${SPARKLE_PRIVATE_KEY_FILE:-}"
STAGING_DIR="$(mktemp -d /tmp/batuta-appcast.XXXXXX)"
trap 'rm -rf "$STAGING_DIR"' EXIT

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "ZIP not found: $ZIP_PATH (run make build-release first)" >&2
  exit 1
fi

KEY_ARGUMENTS=()
if [[ -n "$SPARKLE_PRIVATE_KEY_FILE" ]]; then
  KEY_ARGUMENTS=(--ed-key-file "$SPARKLE_PRIVATE_KEY_FILE")
fi

[[ -x "$SPARKLE_BIN_DIR/generate_appcast" ]] || swift package resolve
cp "$ZIP_PATH" "$STAGING_DIR/"
[[ -f "$APPCAST_PATH" ]] && cp "$APPCAST_PATH" "$STAGING_DIR/appcast.xml"

"$SPARKLE_BIN_DIR/generate_appcast" ${KEY_ARGUMENTS[@]+"${KEY_ARGUMENTS[@]}"} \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
  "$STAGING_DIR"

cp "$STAGING_DIR/appcast.xml" "$APPCAST_PATH"
echo "Updated $APPCAST_PATH for v$VERSION"
