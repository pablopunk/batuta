#!/usr/bin/env bash
# Sourced by the build and release scripts.

BATUTA_GITHUB_REPOSITORY="${BATUTA_GITHUB_REPOSITORY:-${GITHUB_REPOSITORY:-pablopunk/batuta}}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-36LJpGS8rTs3zPSj/ak2mIQhGEMVBSMzlXj7eJGSdSk=}"
SPARKLE_APPCAST_URL="${SPARKLE_APPCAST_URL:-https://raw.githubusercontent.com/$BATUTA_GITHUB_REPOSITORY/main/appcast.xml}"
# Same Apple ID and team as Mousetrap, so its notarytool keychain profile works here too.
DEFAULT_NOTARY_KEYCHAIN_PROFILE="Mousetrap"
HOMEBREW_TAP_REPOSITORY="${HOMEBREW_TAP_REPOSITORY:-pablopunk/homebrew-brew}"
SPARKLE_BIN_DIR="$ROOT/.build/artifacts/sparkle/Sparkle/bin"

release_setting_is_todo() {
  [[ "$1" == *TODO* ]]
}

fail_if_release_settings_have_todos() {
  local name
  for name in BATUTA_GITHUB_REPOSITORY SPARKLE_PUBLIC_ED_KEY SPARKLE_APPCAST_URL; do
    if release_setting_is_todo "${!name}"; then
      echo "Set $name in scripts/release-settings.sh (still ${!name})." >&2
      exit 1
    fi
  done
}
