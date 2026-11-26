# Rules for Agents

* Only move or resize windows as part of an explicit layout action (like adding a stage to the current one), and always through `WindowAnimator` so it looks animated. Navigation itself only reads, raises and focuses.
* The highlight overlay must stay a click-through, non-activating `NSPanel`; it must never become key or steal focus.
* Keyboard input goes through the global event tap in `HotkeyTap`. Only swallow keys Batuta handles: direction keys (hjkl or arrows) with the exact chosen modifier, and direction keys/Return/Escape while a stage is being picked.
* Windows of other stages are reported on-screen by CoreGraphics with thumbnail-sized bounds; only windows whose CG bounds match their AX size belong to the current stage.
* Stage Manager's strip is `com.apple.WindowManager` → AX element with identifier `sm.strip` → `AXButton` children. `AXPress` on them is ignored, so a stage opens by focusing the window whose CG thumbnail sits inside the button.
* Hiding the menu bar icon must never make the app unreachable; reopening the app restores it.
- Stage Manager hides the strip when windows reach the screen edge. While picking, `StageStripReveal` parks the pointer on that edge with a real mouse-move event and puts it back after the action; keep it that way rather than drawing our own strip.
- The app icon's only source is `assets/AppIcon.icon` (Icon Composer). Whenever it changes, run `make icons` and commit everything it regenerates (`assets/AppIcon.icns`, `assets/AppIcon.png`, `www/public/icon.png`); never edit those by hand.

## Behavior

The README stays minimal on purpose; this is the reference for what Batuta does.

Keyboard navigation for macOS Stage Manager, without moving windows.

- **Modifier + h/j/k/l** focuses the window on that side in the current stage, following what is on screen.
- With no window on that side, going toward Stage Manager (or up/down) starts picking a stage.
- **Move modifier + h/l** (default: navigate keys + ⇧) swaps the focused window with its neighbour; at the edge next to Stage Manager it sends the window out of the stage.
- While a stage is selected, **Move modifier + l** pulls it into the current stage (release the keys to drop it).
- Hold **Navigate** for a moment to see numbers on the Stage Manager thumbnails; **Navigate + 1–9** opens that stage (1 is the top one).
- **Navigate + +/-** resizes the focused window by 1/12 of the screen per press. In Even and BSP stages its neighbours give or take the same space, so tiles never overlap; in other modes, or alone, it grows or shrinks around its center.
- **k/j** moves through the stages and wraps around (up from the window opens the last stage, down the first), **release the modifier** (or press **↩**, set in settings) to open it, **Esc** cancels.

Navigate defaults to ⌃⌘, Move adds ⇧, and the keys to the arrows (hjkl is an option). Settings live in `~/.config/batuta/config.json`.

### Tiling

Pick the default mode for every stage in the Tiling tab (saved as `tiling.mode` in the config):

- **Off**: windows stay where they are; a mode shortcut can still tile one stage.
- **Even** (default): every window gets the same space: one row up to 3 windows, then rows of up to 3 (5 is 2 over 3).
- **BSP**: each new window splits the last one in half, side by side then top and bottom.
- **Messy**: loose hand-drawn layouts for 1 to 5 windows that can overlap; more windows use Even. With "Learn app size" on (`rememberAppSizes` in `tiling` / `externalTiling`, off by default), when an app's window is alone in a Messy or Custom stage and you move or resize it (mouse drag or Navigate + +/-), Batuta saves that place for the app in `~/.config/batuta/apps.json` (`laptop` and `external` lists, keyed by bundle ID; External uses `laptop` unless it has its own settings), and uses it next time. With it off nothing is learned or applied, but saved sizes stay in apps.json. The Tiling tab lists them (only while on) so you can forget one.
- **Custom**: draw tiles for 1 to 6 windows; saved as `customLayouts` inside `tiling` / `externalTiling` (only the counts you changed), keyed by window count, as 0–1 rects (`x`, `y`, `width`, `height`, top-left origin). Tile 1 is the leftmost window.

**Floating windows** are detected automatically, with no settings. They are never tiled, swapped, step-resized or learned in apps.json, and do not count as windows of the stage; you can still focus them and send them out of the stage. The first rule that matches decides:

1. A window whose size or position Batuta cannot set floats.
2. Chrome, Activity Monitor and GIMP windows are tiled (their normal windows can lack a working full-screen button).
3. Simulator and Photo Booth float.
4. A window with a close button whose full-screen button is missing or disabled floats (dialogs, About boxes, System Settings). Windows without title bar buttons are tiled.

An Accessibility value Batuta cannot read never makes a window float. The traits are read when a window first shows, once more 0.3 s later, then kept by window ID.

**Don't cover Stage Manager** (`tiling.leaveRoomForStageManager`, on by default) keeps windows clear of Stage Manager. Turn it off to tile over the whole screen.

The Laptop settings (`tiling`) apply to every screen. Turn on **Own settings** in the External tab (`externalScreensHaveOwnTiling`) to give external screens their own `externalTiling`.

**Navigate + Space** (change it in the Tiling tab, saved as `cycleTilingModeShortcut`) cycles the current stage to the next mode and tiles it now. Only that stage changes; it keeps the mode until Batuta quits, and other stages keep the default. Each mode can also have its own shortcut (`modeShortcuts`, none by default) that toggles that mode on the current stage: press it again to go back to the mode before. In a recorder, Esc or Delete clears the shortcut.

Batuta tiles when a stage window is pulled in, when a window leaves the stage, and when you switch to another stage by keyboard or mouse (**Tile on stage switch**, `tileWhenSwitchingStages`, on by default). A stage that comes back with the same windows is left as it is, so sizes you changed by hand stay; when windows joined or left, the others keep their order.


## Release

Release from a clean `main` that matches `origin/main` with `make release VERSION=x.y.z`. It only bumps `VERSION`, commits "Release vx.y.z", tags `vx.y.z` and pushes `main` and the tag together. The tag starts the `Release` GitHub Action (`.github/workflows/release.yml`, on the `xcode-27` runner), which:

1. imports the Developer ID certificate into a temporary keychain and stores notary credentials there (`scripts/ci/`),
2. runs `make build-release`: Developer ID signed, hardened-runtime `Batuta.app`, notarized, stapled, zipped to `dist/Batuta.zip` with a `.sha256`,
3. checks that the Sparkle key matches `SPARKLE_PUBLIC_ED_KEY`,
4. runs `scripts/publish-release.sh`: creates the GitHub release with the zip, the sha256 and generated notes, then commits the signed `appcast.xml` to `main` (so the appcast only points at assets that exist),
5. updates the `batuta` cask in `pablopunk/homebrew-brew`.

Run the workflow by hand (`gh workflow run Release`) for a dry run: it builds, signs, notarizes and checks the Sparkle key, uploads `dist/` as a run artifact, and publishes nothing.

Repository secrets the workflow needs: `MACOS_CERT_P12_BASE64` and `MACOS_CERT_PASSWORD` (only the "Developer ID Application" identity, as p12), `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `SPARKLE_PRIVATE_KEY` (export it with `.build/artifacts/sparkle/Sparkle/bin/generate_keys -x <file>`) and `GH_PAT` (a fine-grained token with contents write on `pablopunk/homebrew-brew`).

The release build must use the Xcode 27 toolchain: Swift 6.3 (Xcode 26) crashes compiling Batuta with `-O`.

Sparkle is only active in release builds: `build-app.sh` writes `SUFeedURL`/`SUPublicEDKey` into `Info.plist` when `CONFIGURATION=release` (override with `ENABLE_SPARKLE_UPDATES`), and `AppUpdater` does nothing without them, so `make run` ("Batuta Dev.app") never updates itself. `scripts/embed-sparkle.sh` copies `Sparkle.framework` into `Contents/Frameworks` and signs its parts inside out; keep signing the app without `--deep`.

`make build-release` alone signs ad-hoc and skips notarization; `SKIP_NOTARIZE=1` skips it with a real identity.
