#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TAG="${1:?Usage: ./scripts/publish-release.sh vX.Y.Z}"
VERSION="${TAG#v}"
ZIP_PATH="$ROOT/dist/Batuta.zip"
SHA_PATH="$ZIP_PATH.sha256"
: "${SPARKLE_PRIVATE_KEY_FILE:?Set SPARKLE_PRIVATE_KEY_FILE to sign the appcast}"

previous_release_tag() {
  git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | grep -vx "$TAG" | head -1 || true
}

commit_list_since() {
  local previous_tag="$1"
  local range="$TAG"
  [[ -n "$previous_tag" ]] && range="$previous_tag..$TAG"
  local commits
  commits="$(git log --pretty=format:'- %s (%h)' "$range")"
  [[ -n "$commits" ]] && printf '## All Commits\n%s\n\n' "$commits"
  return 0
}

create_github_release_with_assets() {
  if gh release view "$TAG" >/dev/null 2>&1; then
    echo "GitHub release $TAG already exists; replacing its assets."
    gh release upload "$TAG" "$ZIP_PATH" "$SHA_PATH" --clobber
    return 0
  fi

  local previous_tag notes
  previous_tag="$(previous_release_tag)"
  notes="$(commit_list_since "$previous_tag")"
  local arguments=("$TAG" "$ZIP_PATH" "$SHA_PATH" --title "$TAG" --verify-tag --generate-notes --notes "$notes")
  [[ -n "$previous_tag" ]] && arguments+=(--notes-start-tag "$previous_tag")
  gh release create "${arguments[@]}"
}

publish_appcast_on_main_after_release_assets_exist() {
  git fetch origin main
  git checkout -B main origin/main
  RELEASE_VERSION="$VERSION" "$ROOT/scripts/generate-appcast.sh" "$ZIP_PATH"

  if git diff --quiet -- appcast.xml; then
    echo "appcast.xml already lists $TAG."
    return 0
  fi

  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git add appcast.xml
  git commit -m "Update appcast for $TAG"
  git push origin main
}

create_github_release_with_assets
publish_appcast_on_main_after_release_assets_exist
echo "Published $TAG"
