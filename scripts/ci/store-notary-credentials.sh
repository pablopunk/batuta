#!/usr/bin/env bash
set -euo pipefail

: "${APPLE_ID:?}" "${APPLE_TEAM_ID:?}" "${APPLE_APP_SPECIFIC_PASSWORD:?}" "${SIGNING_KEYCHAIN:?}" "${GITHUB_ENV:?}"

PROFILE="batuta-notary"

xcrun notarytool store-credentials "$PROFILE" --keychain "$SIGNING_KEYCHAIN" \
  --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" >/dev/null

echo "NOTARY_KEYCHAIN_PROFILE=$PROFILE" >> "$GITHUB_ENV"
echo "NOTARY_KEYCHAIN=$SIGNING_KEYCHAIN" >> "$GITHUB_ENV"
echo "Stored notary credentials as $PROFILE"
