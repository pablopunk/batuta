# Rules for Agents

* Never move or resize windows. Batuta only reads Accessibility data, raises/focuses windows and presses Stage Manager strip buttons, so Stage Manager keeps its own animations.
* The highlight overlay must stay a click-through, non-activating `NSPanel`; it must never become key or steal focus.
* Keyboard input goes through the global event tap in `HotkeyTap`. Only swallow keys Batuta handles: arrows with the exact chosen modifier, and arrows/Return/Escape while a stage is being picked.
* Windows of other stages are reported on-screen by CoreGraphics with thumbnail-sized bounds; only windows whose CG bounds match their AX size belong to the current stage.
* Stage Manager's strip is `com.apple.WindowManager` → AX element with identifier `sm.strip` → `AXButton` children with `AXPress`.
* Hiding the menu bar icon must never make the app unreachable; reopening the app restores it.
