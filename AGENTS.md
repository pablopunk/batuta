# Rules for Agents

* Only move or resize windows as part of an explicit layout action (like adding a stage to the current one), and always through `WindowAnimator` so it looks animated. Navigation itself only reads, raises and focuses.
* The highlight overlay must stay a click-through, non-activating `NSPanel`; it must never become key or steal focus.
* Keyboard input goes through the global event tap in `HotkeyTap`. Only swallow keys Batuta handles: direction keys (hjkl or arrows) with the exact chosen modifier, and direction keys/Return/Escape while a stage is being picked.
* Windows of other stages are reported on-screen by CoreGraphics with thumbnail-sized bounds; only windows whose CG bounds match their AX size belong to the current stage.
* Stage Manager's strip is `com.apple.WindowManager` → AX element with identifier `sm.strip` → `AXButton` children. `AXPress` on them is ignored, so a stage opens by focusing the window whose CG thumbnail sits inside the button.
* Hiding the menu bar icon must never make the app unreachable; reopening the app restores it.
- Stage Manager hides the strip when windows reach the screen edge. While picking, `StageStripReveal` parks the pointer on that edge with a real mouse-move event and puts it back after the action; keep it that way rather than drawing our own strip.

## Behavior

The README stays minimal on purpose; this is the reference for what Batuta does.

Keyboard navigation for macOS Stage Manager, without moving windows.

- **Modifier + h/j/k/l** focuses the window on that side in the current stage, following what is on screen.
- With no window on that side, going toward Stage Manager (or up/down) starts picking a stage.
- **Move modifier + h/l** (default: navigate keys + ⇧) swaps the focused window with its neighbour; at the edge next to Stage Manager it sends the window out of the stage.
- While a stage is selected, **Move modifier + l** pulls it into the current stage (release the keys to drop it).
- Hold **Navigate** for a moment to see numbers on the Stage Manager thumbnails; **Navigate + 1–9** opens that stage (1 is the top one).
- **Navigate + +/-** resizes the focused window by 1/12 of the screen per press. In Even and BSP stages its neighbours give or take the same space, so tiles never overlap; in other modes, or alone, it grows or shrinks around its center.
- **k/j** moves through the stages, **release the modifier** (or press **↩**, set in settings) to open it, **Esc** cancels.

Navigate defaults to ⌃⌘, Move adds ⇧, and the keys to the arrows (hjkl is an option). Settings live in `~/.config/batuta/config.json`.

### Tiling

Pick the default mode for every stage in the Tiling tab (saved as `tiling.mode` in the config):

- **Off**: windows stay where they are; a mode shortcut can still tile one stage.
- **Even** (default): every window gets the same space: one row up to 3 windows, then rows of up to 3 (5 is 2 over 3).
- **BSP**: each new window splits the last one in half, side by side then top and bottom.
- **Messy**: loose hand-drawn layouts for 1 to 6 windows that can overlap; more windows use Even. When an app's window is alone in a Messy stage and you move or resize it (mouse drag or Navigate + +/-), Batuta saves that place for the app in `appSizes`, keyed by bundle ID, and uses it next time. The Tiling tab lists them so you can forget one.
- **Custom**: draw tiles for 1 to 6 windows; saved as `customLayouts`, keyed by window count, as 0–1 rects (`x`, `y`, `width`, `height`, top-left origin). Tile 1 is the leftmost window.

**Leave room** (`tiling.leaveRoomForStageManager`, on by default) keeps windows clear of Stage Manager. Turn it off to tile over the whole screen.

The Laptop settings (`tiling`) apply to every screen. Turn on **Own settings** in the External tab (`externalScreensHaveOwnTiling`) to give external screens their own `externalTiling`.

**Navigate + Space** (change it in the Tiling tab, saved as `cycleTilingModeShortcut`) cycles the current stage to the next mode and tiles it now. Only that stage changes; it keeps the mode until Batuta quits, and other stages keep the default. Each mode can also have its own shortcut (`modeShortcuts`, none by default) that toggles that mode on the current stage: press it again to go back to the mode before. In a recorder, Esc or Delete clears the shortcut.

Batuta tiles when a stage window is pulled in, when a window leaves the stage, and when you switch to another stage by keyboard or mouse (**Tile on stage switch**, `tileWhenSwitchingStages`, on by default). A stage that comes back with the same windows is left as it is, so sizes you changed by hand stay; when windows joined or left, the others keep their order.

