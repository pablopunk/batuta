#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RAW_VERSION="${1:-}"
if [[ -z "$RAW_VERSION" ]]; then
  echo "Usage: ./scripts/release.sh x.y.z"
  exit 1
fi

VERSION="${RAW_VERSION#v}"
TAG="v$VERSION"

fail_unless_version_looks_like_semver() {
  if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Version must look like x.y.z" >&2
    exit 1
  fi
}

fail_unless_on_clean_main_matching_origin() {
  if [[ "$(git branch --show-current)" != "main" ]]; then
    echo "Release from main only. Current branch: $(git branch --show-current)" >&2
    exit 1
  fi
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree must be clean before releasing." >&2
    git status --short
    exit 1
  fi
  git fetch --tags origin main
  if [[ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]]; then
    echo "Local main differs from origin/main. Pull or push first." >&2
    exit 1
  fi
}

fail_if_tag_exists() {
  if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Tag already exists: $TAG" >&2
    exit 1
  fi
}

commit_version_bump() {
  printf '%s\n' "$VERSION" > "$ROOT/VERSION"
  git add VERSION
  if git diff --cached --quiet; then
    echo "VERSION already at $VERSION"
  else
    git commit -m "Release $TAG"
  fi
}

push_main_and_tag_to_start_the_release_workflow() {
  git tag "$TAG"
  git push --atomic origin main "refs/tags/$TAG"
}

fail_unless_version_looks_like_semver
fail_unless_on_clean_main_matching_origin
fail_if_tag_exists
commit_version_bump
push_main_and_tag_to_start_the_release_workflow

echo "Pushed $TAG. The Release workflow now builds, notarizes and publishes it:"
echo "  gh run list --workflow Release --limit 1"
