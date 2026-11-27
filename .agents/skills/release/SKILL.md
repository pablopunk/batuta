---
name: release
description: Cut a Batuta release from a bump word (patch/minor/major) or a version, then name it and write its GitHub release notes. Use when the user says "release", "release patch/minor/major", or asks for release notes or a release name.
---

# Release

`make release VERSION=x.y.z` only bumps `VERSION`, commits, tags `vX.Y.Z` and pushes `main` and the tag. The tag starts the `Release` GitHub Action, which builds, signs and notarizes `Batuta.app`, creates the GitHub release with generated notes, commits the signed `appcast.xml` to `main` and updates the Homebrew cask. See "Release" in `AGENTS.md` for the secrets it needs.

Cut first, name later: run `make release` right away, before you ask for the name or write the notes. The name and notes go on the release only after the action finishes, so ask for them while it builds. A bump word ("release minor") is the go-ahead to cut; do not ask again.

## Cut

1. `git fetch --tags origin`; read the latest tag with `git tag --sort=-v:refname | head -1`.
2. Bump it for the word used: *patch* (`0.1.4` → `0.1.5`), *minor* (`0.1.4` → `0.2.0`), *major* (`0.1.4` → `1.0.0`).
3. Say the computed version, then run `make release VERSION=x.y.z` from a clean `main` that matches `origin/main`.
4. Watch the action: `gh run watch "$(gh run list --workflow Release --limit 1 --json databaseId -q '.[0].databaseId')" --exit-status` (a few minutes while Apple notarizes). If it fails, read `gh run view <id> --log-failed`, fix, and re-run it with `gh run rerun <id> --failed`; publishing is safe to repeat.
5. `git pull` so local `main` has the appcast commit the action pushed.

## Notes

Do this while the action from step 4 runs.

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
5. Once the action has created the release, stage the body in a scratch file and publish it:

   ```sh
   gh release edit vX.Y.Z --title "vX.Y.Z - <Name>" --notes-file <path>
   ```

## After

- To check the pipeline without cutting a version, run the dry run: `gh workflow run Release`. It builds, signs and notarizes but publishes nothing.
