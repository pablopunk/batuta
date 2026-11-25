import { highlightSwift } from "./swiftHighlight";
import "./editor.css";

const SOURCE = `import AppKit
@preconcurrency import CoreGraphics

enum Direction {
    case left, right, up, down

    init?(keyCode: Int64, keys: DirectionKeys) {
        switch (keys, keyCode) {
        case (.arrows, 123), (.hjkl, 4): self = .left
        case (.arrows, 124), (.hjkl, 37): self = .right
        case (.arrows, 125), (.hjkl, 38): self = .down
        case (.arrows, 126), (.hjkl, 40): self = .up
        default: return nil
        }
    }
}

private enum KeyCode {
    static let returnKey: Int64 = 36
    static let escape: Int64 = 53
    static let keypadPlus: Int64 = 69
    static let keypadMinus: Int64 = 78
}

/// Global keyboard tap. It only swallows keys Batuta handles.
@MainActor
final class HotkeyTap {
    var onDirection: ((Direction) -> Void)?
    var onMoveDirection: ((Direction) -> Void)?
    var onCycleTilingMode: (() -> Void)?
    var onStageNumber: ((Int) -> Void)?
    var onResize: ((_ grows: Bool) -> Void)?
    var isPickingStage: () -> Bool = { false }
}`.split("\n");

const CURRENT_LINE = 9;

const TREE: [depth: number, name: string, kind: "folder" | "swift" | "markdown", active?: boolean][] = [
  [0, "Sources", "folder"],
  [1, "AppDelegate.swift", "swift"],
  [1, "HighlightOverlay.swift", "swift"],
  [1, "HotkeyTap.swift", "swift", true],
  [1, "StageNavigator.swift", "swift"],
  [1, "StageStrip.swift", "swift"],
  [1, "Tiling", "folder"],
  [2, "StageTilingModes.swift", "swift"],
  [2, "TilingLayouts.swift", "swift"],
  [1, "Views", "folder"],
  [2, "SettingsView.swift", "swift"],
  [1, "WindowAnimator.swift", "swift"],
  [0, "Package.swift", "swift"],
  [0, "README.md", "markdown"],
];

const FILE_ICONS = { folder: "▾", swift: "S", markdown: "M" };

const TABS = ["HotkeyTap.swift", "StageStrip.swift", "TilingLayouts.swift"];

export function Editor() {
  return (
    <div className="app editor">
      <aside className="explorer">
        <div className="explorer-title">Explorer</div>
        <div className="explorer-project">▾ BATUTA</div>
        {TREE.map(([depth, name, kind, active]) => (
          <div key={name} className={active ? "tree-item active" : "tree-item"} style={{ paddingLeft: 14 + depth * 12 }}>
            <span className={`file-icon ${kind}`}>{FILE_ICONS[kind]}</span>
            {name}
          </div>
        ))}
      </aside>
      <section className="editor-main">
        <div className="tabs">
          {TABS.map((tab, index) => (
            <div key={tab} className={index === 0 ? "tab active" : "tab"}>
              <span className="file-icon swift">S</span>
              {tab}
            </div>
          ))}
        </div>
        <div className="breadcrumbs">Sources › HotkeyTap.swift › Direction › init(keyCode:keys:)</div>
        <div className="code">
          {SOURCE.map((line, index) => (
            <div key={index} className={index + 1 === CURRENT_LINE ? "code-line current" : "code-line"}>
              <span className="gutter">{index + 1}</span>
              <span className="text">
                {highlightSwift(line).map((token, tokenIndex) => (
                  <span key={tokenIndex} className={token.kind}>{token.text}</span>
                ))}
              </span>
            </div>
          ))}
        </div>
        <div className="statusbar">
          <span>⎇ main</span>
          <span>⊘ 0 ⚠ 0</span>
          <span className="spacer" />
          <span>Ln {CURRENT_LINE}, Col 42</span>
          <span>Spaces: 4</span>
          <span>UTF-8</span>
          <span>Swift</span>
        </div>
      </section>
    </div>
  );
}
