#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:?Usage: embed-sparkle.sh /path/to/App.app /path/to/Sparkle.framework codesign-identity}"
SPARKLE_FRAMEWORK="${2:?Missing Sparkle.framework path}"
CODESIGN_IDENTITY="${3:?Missing codesign identity}"
EXECUTABLE="$APP_DIR/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_DIR/Contents/Info.plist")"
FRAMEWORKS_DIR="$APP_DIR/Contents/Frameworks"
EMBEDDED_SPARKLE="$FRAMEWORKS_DIR/Sparkle.framework"
SPARKLE_VERSION_DIR="$EMBEDDED_SPARKLE/Versions/B"

SIGN_OPTIONS=(--force --sign "$CODESIGN_IDENTITY")
if [[ "$CODESIGN_IDENTITY" != "-" ]]; then
  SIGN_OPTIONS+=(--options runtime --timestamp)
fi

copy_framework_into_app() {
  mkdir -p "$FRAMEWORKS_DIR"
  rm -rf "$EMBEDDED_SPARKLE"
  ditto "$SPARKLE_FRAMEWORK" "$EMBEDDED_SPARKLE"
}

let_executable_find_embedded_frameworks() {
  if ! otool -l "$EXECUTABLE" | grep -q "@executable_path/../Frameworks"; then
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$EXECUTABLE"
  fi
}

sign_sparkle_inside_out_as_sparkle_docs_require() {
  codesign "${SIGN_OPTIONS[@]}" "$SPARKLE_VERSION_DIR/XPCServices/Installer.xpc"
  codesign "${SIGN_OPTIONS[@]}" --preserve-metadata=entitlements "$SPARKLE_VERSION_DIR/XPCServices/Downloader.xpc"
  codesign "${SIGN_OPTIONS[@]}" "$SPARKLE_VERSION_DIR/Autoupdate"
  codesign "${SIGN_OPTIONS[@]}" "$SPARKLE_VERSION_DIR/Updater.app"
  codesign "${SIGN_OPTIONS[@]}" "$EMBEDDED_SPARKLE"
}

copy_framework_into_app
let_executable_find_embedded_frameworks
sign_sparkle_inside_out_as_sparkle_docs_require
echo "Embedded and signed $(basename "$SPARKLE_FRAMEWORK")"
