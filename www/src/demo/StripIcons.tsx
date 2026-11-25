import { APP_ICONS } from "./apps/icons";
import type { StripIconRow } from "./placements";

/** The app icons Stage Manager draws at the bottom left of each thumbnail, one per app in the stage. */
export function StripIcons({ rows }: { rows: StripIconRow[] }) {
  return (
    <>
      {rows.map((row) => (
        <div
          key={row.stageId}
          className={row.hidden ? "strip-icons hidden" : "strip-icons"}
          style={{ left: row.x, top: row.y, zIndex: row.z }}
        >
          {row.apps.map((app) => {
            const icon = APP_ICONS[app];
            return (
              <span key={app} className="app-icon" style={{ background: icon.background, color: icon.color }}>
                {icon.glyph}
              </span>
            );
          })}
        </div>
      ))}
    </>
  );
}
