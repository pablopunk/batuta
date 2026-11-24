# Rules for Agents

* Only move or resize windows as part of an explicit layout action (like adding a stage to the current one), and always through `WindowAnimator` so it looks animated. Navigation itself only reads, raises and focuses.
* The highlight overlay must stay a click-through, non-activating `NSPanel`; it must never become key or steal focus.
* Keyboard input goes through the global event tap in `HotkeyTap`. Only swallow keys Batuta handles: direction keys (hjkl or arrows) with the exact chosen modifier, and direction keys/Return/Escape while a stage is being picked.
* Windows of other stages are reported on-screen by CoreGraphics with thumbnail-sized bounds; only windows whose CG bounds match their AX size belong to the current stage.
* Stage Manager's strip is `com.apple.WindowManager` → AX element with identifier `sm.strip` → `AXButton` children. `AXPress` on them is ignored, so a stage opens by focusing the window whose CG thumbnail sits inside the button.
* Hiding the menu bar icon must never make the app unreachable; reopening the app restores it.
- Stage Manager hides the strip when windows reach the screen edge. While picking, `StageStripReveal` parks the pointer on that edge with a real mouse-move event and puts it back after the action; keep it that way rather than drawing our own strip.
