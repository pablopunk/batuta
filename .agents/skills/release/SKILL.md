---
name: release
description: Cut a Batuta release from a bump word (patch/minor/major) or a version, then name it and write its GitHub release notes. Use when the user says "release", "release patch/minor/major", or asks for release notes or a release name.
---

# Release

`make release VERSION=x.y.z` runs everything locally from a clean `main`: bumps `VERSION`, builds and notarizes `Batuta.app`, updates `appcast.xml`, tags `vX.Y.Z`, creates the GitHub release with generated notes and pushes `main`. The `Release` GitHub Action then updates the Homebrew cask. See "Release" in `AGENTS.md` for the one-time setup.

## Cut

1. `git fetch --tags origin`; read the latest tag with `git tag --sort=-v:refname | head -1`.
2. Bump it for the word used: *patch* (`0.1.4` → `0.1.5`), *minor* (`0.1.4` → `0.2.0`), *major* (`0.1.4` → `1.0.0`).
3. Say the computed version, then run `make release VERSION=x.y.z` (it takes a few minutes while Apple notarizes).

## Notes

1. Gather what ships: `git log --oneline vPREV..vNEW` (skip the `Update appcast` and `VERSION` commits). Read the diffs, not only the messages, for user-facing changes. Ignore website-only and agent-file changes unless they matter to users.
2. Copy the house style from `gh release view vPREV`.
3. Ask Pablo to pick the release name: 2–4 words (*Take a bow*, *First rehearsal*, *In tempo*). Offer a few options; Batuta is a conductor's baton, so music and orchestra puns fit.
4. Draft the body:

   ```markdown
   ## Batuta X.Y.Z — <Name>

   <one sentence summary of the release>.

   - 🎹 **Area** — user-facing change.
   - …

   **Full changelog**: https://github.com/pablopunk/batuta/compare/vPREV...vNEW
   ```

   One bullet per area with an emoji and a bold label; write for users, not as a commit dump. Keep the summary true for the whole release.
5. Stage the body in a scratch file and publish it:

   ```sh
   gh release edit vX.Y.Z --title "vX.Y.Z - <Name>" --notes-file <path>
   ```

## After

- Check the `Release` action with `gh run list --workflow Release --limit 1`. It fails without the `GH_PAT` secret (a token that can push to `pablopunk/homebrew-brew`).
