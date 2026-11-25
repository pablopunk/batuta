import { useLayoutEffect, useRef, useState } from "react";
import { SCREEN } from "./geometry";
import { MODE_LABELS, TILING_MODES, type TilingMode } from "./layouts";
import { LayoutCanvas } from "./settings/LayoutCanvas";
import { MODE_SHORTCUT_KEYS, MODE_SHORTCUT_MODIFIERS, NAVIGATE } from "./shortcuts";
import { modeRects, type DesktopState } from "./state";
import { Icon } from "./settings/icons";
import { CaptionedRow, Pill, SectionHeader, Shortcut, ToggleRow } from "./settings/rows";
import "./settings/settings.css";


const MODE_CAPTIONS: Record<TilingMode, string> = {
  off: "Batuta leaves windows where they are. The shortcut can still tile one stage.",
  even: "Every window gets the same space, in rows.",
  bsp: "Each new window splits the last one in half.",
  messy: "Loose layouts where windows can overlap.",
  custom: "Draw where windows go for 1 to 6 windows. Drag to move, drag the corner to resize. Tile 1 is the leftmost window.",
};

const TABS = [
  { icon: "gear", label: "Settings" },
  { icon: "grid", label: "Tiling" },
  { icon: "info", label: "About" },
] as const;

const shortcutLabel = (modifiers: string[], key: string) => `${modifiers.join("")} ${key}`;

const modeShortcutLabel = (mode: TilingMode) => {
  const key = MODE_SHORTCUT_KEYS[mode];
  return key ? shortcutLabel(MODE_SHORTCUT_MODIFIERS, key) : "None";
};

const PANEL_INSET_FROM_ICON = 16;
const PANEL_WIDTH = 320;
const SCREEN_EDGE_MARGIN = 8;

function useLeftEdgeUnderMenuBarIcon() {
  const panel = useRef<HTMLDivElement>(null);
  const [left, setLeft] = useState<number>();
  useLayoutEffect(() => {
    const icon = panel.current?.closest(".screen")?.querySelector<HTMLElement>(".batuta-icon");
    if (icon) setLeft(Math.min(icon.offsetLeft - PANEL_INSET_FROM_ICON, SCREEN.w - PANEL_WIDTH - SCREEN_EDGE_MARGIN));
  }, []);
  return { panel, left };
}

/** The Tiling tab of Batuta's menu bar panel, as in TilingView.swift. */
export function SettingsPanel({ state }: { state: DesktopState }) {
  const { panel, left } = useLeftEdgeUnderMenuBarIcon();
  const mode = state.defaultMode;
  const { windowCount, activeTile } = state.panel;
  return (
    <div ref={panel} className="settings-panel" style={{ left, width: PANEL_WIDTH }}>
      <div className="panel-tabs">
        {TABS.map((tab) => (
          <span key={tab.label} className={tab.label === "Tiling" ? "panel-tab on" : "panel-tab"}>
            <Icon name={tab.icon} size={13} />
            {tab.label === "Tiling" && tab.label}
          </span>
        ))}
      </div>

      <div className="panel-body">
        <div className="tiling-header">
          <SectionHeader title="Tiling" icon="grid" />
          <Pill label="Laptop" on />
          <Pill label="External" on={false} />
        </div>

        <div className="mode-pills">
          {TILING_MODES.map((item) => (
            <Pill key={item} label={MODE_LABELS[item]} on={item === mode} pointer={`mode-${item}`} />
          ))}
        </div>
        <p className="mode-caption">Default for every stage. {MODE_CAPTIONS[mode]}</p>

        {mode !== "off" && (
          <>
            <div className="window-stepper">
              <span>Windows</span>
              <i><Icon name="minus" size={10} /></i>
              <b>{windowCount}</b>
              <i><Icon name="plus" size={10} /></i>
            </div>
            <LayoutCanvas rects={modeRects(state, windowCount, mode)} editable={mode === "custom"} activeTile={activeTile} />
          </>
        )}

        <ToggleRow title="Don't cover Stage Manager" subtitle="Tile beside the thumbnails" icon="sidebar" on={state.leaveRoomForStageManager} pointer="leave-room-toggle" />
        <ToggleRow title="Learn app size" subtitle="For 1-window stages" icon="window" on={false} />
        <ToggleRow title="Tile on stage switch" subtitle="Also when you click a stage" icon="stack" on />

        <CaptionedRow
          title="Cycle mode"
          icon="cycle"
          caption="Changes the mode of the current stage only. Other stages keep the default. Click the shortcut to change it, or press Esc to clear it."
        >
          <Shortcut label={shortcutLabel(NAVIGATE, "Space")} />
        </CaptionedRow>

        <CaptionedRow title="Mode shortcuts" icon="keyboard" caption="Sets that mode on the current stage. Press it again to go back. Esc clears a shortcut." />
        <div className="mode-shortcuts">
          {TILING_MODES.map((item) => (
            <div key={item}>
              <span>{MODE_LABELS[item]}</span>
              <Shortcut label={modeShortcutLabel(item)} />
            </div>
          ))}
        </div>
      </div>

      <div className="config-path">
        <Icon name="file" size={12} />
        ~/.config/batuta/config.json
      </div>
    </div>
  );
}
