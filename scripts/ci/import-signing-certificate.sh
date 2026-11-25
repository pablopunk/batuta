#!/usr/bin/env bash
set -euo pipefail

: "${MACOS_CERT_P12_BASE64:?}" "${MACOS_CERT_PASSWORD:?}" "${RUNNER_TEMP:?}" "${GITHUB_ENV:?}"

KEYCHAIN="$RUNNER_TEMP/batuta-signing.keychain-db"
KEYCHAIN_PASSWORD="$(openssl rand -base64 24)"
CERTIFICATE="$RUNNER_TEMP/batuta-certificate.p12"
trap 'rm -f "$CERTIFICATE"' EXIT

create_unlocked_temporary_keychain() {
  security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
  security set-keychain-settings -lut 21600 "$KEYCHAIN"
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
}

import_certificate_for_codesign_without_prompts() {
  printf '%s' "$MACOS_CERT_P12_BASE64" | base64 --decode > "$CERTIFICATE"
  security import "$CERTIFICATE" -P "$MACOS_CERT_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN"
  security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" >/dev/null
}

add_keychain_to_search_list() {
  local existing=()
  while IFS= read -r listed; do
    existing+=("$(sed -E 's/^[[:space:]]*"(.*)"[[:space:]]*$/\1/' <<<"$listed")")
  done < <(security list-keychains -d user)
  security list-keychains -d user -s "$KEYCHAIN" "${existing[@]}"
}

developer_id_identity_in_keychain() {
  security find-identity -v -p codesigning "$KEYCHAIN" \
    | sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' | head -n 1
}

create_unlocked_temporary_keychain
import_certificate_for_codesign_without_prompts
add_keychain_to_search_list

IDENTITY="$(developer_id_identity_in_keychain)"
if [[ -z "$IDENTITY" ]]; then
  echo "The imported certificate has no Developer ID Application identity." >&2
  exit 1
fi

echo "SIGNING_KEYCHAIN=$KEYCHAIN" >> "$GITHUB_ENV"
echo "CODESIGN_IDENTITY=$IDENTITY" >> "$GITHUB_ENV"
echo "Imported signing identity: $IDENTITY"
