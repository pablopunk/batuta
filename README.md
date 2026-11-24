# Batuta

Keyboard navigation for macOS Stage Manager, without moving windows.

- **Modifier + h/j/k/l** focuses the window on that side in the current stage, following what is on screen.
- With no window on that side, going toward Stage Manager (or up/down) starts picking a stage.
- **Move modifier + h/l** (default: navigate keys + ⇧) swaps the focused window with its neighbour; at the edge next to Stage Manager it sends the window out of the stage.
- While a stage is selected, **Move modifier + l** pulls it into the current stage (release the keys to drop it).
- **k/j** moves through the stages, **release the modifier** (or press **↩**, set in settings) to open it, **Esc** cancels.

The modifier defaults to ⌃⌥⌘ and the keys to hjkl (arrows are an option). Settings live in `~/.config/batuta/config.json`.

## Develop

```sh
make run    # builds, signs and opens "Batuta Dev.app" from /Applications
make build  # builds and installs Batuta.app
```

Batuta needs Accessibility permission.

## Tiling

Pick the default mode for every stage in the Tiling tab (saved as `tiling.mode` in the config):

- **Even**: every window gets the same space: one row up to 3 windows, then rows of up to 3 (5 is 2 over 3).
- **BSP**: each new window splits the last one in half, side by side then top and bottom.
- **Messy**: loose hand-drawn layouts for 1 to 6 windows that can overlap; more windows use Even.
- **Custom**: draw tiles for 1 to 6 windows; saved as `customLayouts`, keyed by window count, as 0–1 rects (`x`, `y`, `width`, `height`, top-left origin). Tile 1 is the leftmost window.

**Leave room** (`tiling.leaveRoomForStageManager`, on by default) keeps windows clear of Stage Manager. Turn it off to tile over the whole screen.

The Laptop settings (`tiling`) apply to every screen. Turn on **Own settings** in the External tab (`externalScreensHaveOwnTiling`) to give external screens their own `externalTiling`.

**⌃⌥⌘ Space** (change it in the Tiling tab, saved as `cycleTilingModeShortcut`) switches the current stage to the next mode and tiles it now. Only that stage changes; it keeps the mode until Batuta quits, and other stages keep the default.

Batuta tiles when a stage window is pulled in, when a window leaves the stage, and when you switch to another stage by keyboard or mouse (**Tile on stage switch**, `tileWhenSwitchingStages`, on by default).
