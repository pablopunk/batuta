# Batuta

Keyboard navigation for macOS Stage Manager, without moving windows.

- **Modifier + ←/→** focuses the window to the left/right in the current stage.
- Go past the edge window toward the Stage Manager strip (or press **Modifier + ↑/↓**) to start picking a stage.
- **↑/↓** moves through the stages, **release the modifier** (or press **↩**, set in settings) to open it, **Esc** cancels.

The modifier defaults to Hyper (⌃⌥⇧⌘) and can be any combination.

## Develop

```sh
make run    # builds, signs and opens "Batuta Dev.app" from /Applications
make build  # builds and installs Batuta.app
```

Batuta needs Accessibility permission.
