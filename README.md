# Batuta

Keyboard navigation for macOS Stage Manager, without moving windows.

- **Modifier + h/l** focuses the window to the left/right in the current stage.
- Go past the edge window toward the Stage Manager strip (or press **Modifier + k/j**) to start picking a stage.
- While a stage is selected, **Modifier + ⇧ + l** pulls it into the current stage.
- **k/j** moves through the stages, **release the modifier** (or press **↩**, set in settings) to open it, **Esc** cancels.

The modifier defaults to ⌃⌥⌘ and the keys to hjkl (arrows are an option). Settings live in `~/.config/batuta/config.json`.

## Develop

```sh
make run    # builds, signs and opens "Batuta Dev.app" from /Applications
make build  # builds and installs Batuta.app
```

Batuta needs Accessibility permission.
