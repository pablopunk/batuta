#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/release-settings.sh"

VERSION="${1:-}"
ZIP_PATH="${2:-}"

if [[ -z "$VERSION" || -z "$ZIP_PATH" ]]; then
  echo "Usage: ./scripts/update-homebrew-cask.sh x.y.z /path/to/Batuta.zip"
  exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "ZIP not found: $ZIP_PATH"
  exit 1
fi

fail_if_release_settings_have_todos

TAP_REPO="${TAP_REPO:-$HOMEBREW_TAP_REPOSITORY}"
TAP_DIR="$(mktemp -d /tmp/batuta-homebrew.XXXXXX)"
CASK_PATH="$TAP_DIR/Casks/batuta.rb"
ZIP_SHA="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
GIT_REMOTE="https://github.com/$TAP_REPO.git"

cleanup() {
  rm -rf "$TAP_DIR"
}
trap cleanup EXIT

if [[ -n "${GH_PAT:-}" ]]; then
  GIT_REMOTE="https://x-access-token:${GH_PAT}@github.com/$TAP_REPO.git"
fi

git clone "$GIT_REMOTE" "$TAP_DIR"

cat > "$CASK_PATH" <<EOF
cask "batuta" do
  version "$VERSION"
  sha256 "$ZIP_SHA"

  url "https://github.com/$BATUTA_GITHUB_REPOSITORY/releases/download/v#{version}/Batuta.zip"
  name "Batuta"
  desc "Keyboard navigation and tiling for macOS Stage Manager"
  homepage "https://github.com/$BATUTA_GITHUB_REPOSITORY"

  auto_updates true
  depends_on macos: ">= :sonoma"

  app "Batuta.app"

  zap trash: [
    "~/.config/batuta",
    "~/Library/Preferences/com.pablopunk.batuta.plist",
    "~/Library/Caches/com.pablopunk.batuta",
  ]
end
EOF

ruby -c "$CASK_PATH"

pushd "$TAP_DIR" >/dev/null
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

if ! git diff --quiet -- Casks/batuta.rb; then
  git add Casks/batuta.rb
  git commit -m "batuta: update to v$VERSION"
  git push
else
  echo "Homebrew cask already up to date."
fi
popd >/dev/null

echo "Updated Homebrew cask to v$VERSION"
