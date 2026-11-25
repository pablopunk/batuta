import { useEffect, useState } from "react";
import { MODE_LABELS, TILING_MODES, type TilingMode } from "./layouts";

const DELAY_BEFORE_SLIDING = 50;

/** Every tiling mode in a bar; the highlight slides from the mode the stage had to the one it switched to. */
export function ModeBanner({ from, to }: { from: TilingMode; to: TilingMode }) {
  const [active, setActive] = useState(from);
  useEffect(() => {
    const timer = setTimeout(() => setActive(to), DELAY_BEFORE_SLIDING);
    return () => clearTimeout(timer);
  }, [to]);

  return (
    <div className="mode-banner" style={{ "--active-index": TILING_MODES.indexOf(active) } as React.CSSProperties}>
      <span className="mode-pill" />
      {TILING_MODES.map((mode) => (
        <span key={mode} className={mode === active ? "mode active" : "mode"}>
          {MODE_LABELS[mode]}
        </span>
      ))}
    </div>
  );
}
