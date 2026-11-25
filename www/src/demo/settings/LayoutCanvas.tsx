import type { UnitRect } from "../geometry";
import { Pill } from "./rows";

const MODES_TO_COPY_FROM = ["Even", "BSP", "Messy"];

const tileStyle = (rect: UnitRect) => ({
  left: `${rect.x * 100}%`,
  top: `${rect.y * 100}%`,
  width: `${rect.w * 100}%`,
  height: `${rect.h * 100}%`,
});

type Props = { rects: UnitRect[]; editable: boolean; activeTile: number | null };

/** The layout preview, or the Custom editor with drag handles and the Copy row, as in CustomLayoutEditor.swift. */
export function LayoutCanvas({ rects, editable, activeTile }: Props) {
  return (
    <div className="layout-editor">
      <div className="layout-canvas">
        {rects.map((rect, index) => (
          <div key={index} data-pointer={`tile-${index}`} className={activeTile === index ? "tile active" : "tile"} style={tileStyle(rect)}>
            {index + 1}
            {editable && <i data-pointer={`tile-handle-${index}`} className="resize-handle">↘</i>}
          </div>
        ))}
      </div>
      {editable && (
        <div className="copy-row">
          <span>Copy</span>
          {MODES_TO_COPY_FROM.map((mode) => (
            <Pill key={mode} label={mode} on={false} />
          ))}
        </div>
      )}
    </div>
  );
}
