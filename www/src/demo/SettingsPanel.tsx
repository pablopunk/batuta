import { MODE_LABELS, TILING_MODES, type TilingMode } from "./layouts";

type Props = { mode: TilingMode; leaveRoomForStageManager: boolean };

const ToggleRow = ({ title, subtitle, on }: { title: string; subtitle: string; on: boolean }) => (
  <div className="settings-row">
    <div>
      <b>{title}</b>
      <span>{subtitle}</span>
    </div>
    <i className={on ? "switch on" : "switch"} />
  </div>
);

/** The Tiling tab of Batuta's menu bar panel, trimmed to what the demo changes. */
export function SettingsPanel({ mode, leaveRoomForStageManager }: Props) {
  return (
    <div className="settings-panel">
      <div className="settings-tabs">
        <span>General</span>
        <span className="on">Tiling</span>
      </div>
      <div className="settings-modes">
        {TILING_MODES.map((item) => (
          <span key={item} className={item === mode ? "on" : undefined}>{MODE_LABELS[item]}</span>
        ))}
      </div>
      <ToggleRow title="Don't cover Stage Manager" subtitle="Tile beside the thumbnails" on={leaveRoomForStageManager} />
      <ToggleRow title="Learn app size" subtitle="For 1-window stages" on={false} />
    </div>
  );
}
