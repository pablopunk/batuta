import { useEffect, useRef, useState } from "react";
import { APPS } from "./apps/index";
import { SCREEN } from "./geometry";
import { MenuBar } from "./MenuBar";
import { ModeBanner } from "./ModeBanner";
import { HighlightFrame, KeyCaps, StageBadges } from "./Overlays";
import { badgeRects, highlight, windowPlacements } from "./placements";
import type { Keys } from "./script";
import type { AppId, DesktopState } from "./state";
import { Window } from "./Window";

const ALL_APPS_IN_STABLE_DOM_ORDER = Object.keys(APPS) as AppId[];

type Props ={ state: DesktopState; keys: (Keys & { count: number }) | null; instant: boolean };

function useScaleToFit() {
  const container = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.5);
  useEffect(() => {
    const element = container.current;
    if (!element) return;
    const observer = new ResizeObserver(([entry]) => setScale(entry.contentRect.width / SCREEN.w));
    observer.observe(element);
    return () => observer.disconnect();
  }, []);
  return { container, scale };
}

/** A pure picture of the desktop state: it never changes state, so anything can drive it. */
export function Desktop({ state, keys, instant }: Props) {
  const { container, scale } = useScaleToFit();
  const placements = windowPlacements(state);
  const frame = highlight(state);
  const focusedApp = state.focused ? APPS[state.focused].name : "Finder";

  return (
    <div className="device">
      <div ref={container} className="screen-fit" style={{ height: SCREEN.h * scale }}>
        <div
          className={instant ? "screen instant" : "screen"}
          style={{ width: SCREEN.w, height: SCREEN.h, transform: `scale(${scale})` }}
        >
          <div className="wallpaper" />
          <MenuBar appName={focusedApp} />
          {ALL_APPS_IN_STABLE_DOM_ORDER.filter((id) => placements[id]).map((id) => (
            <Window key={id} id={id} placement={placements[id]} focused={id === state.focused} />
          ))}
          {frame && <HighlightFrame highlight={frame} flashCount={state.flashCount} />}
          {state.badges && <StageBadges rects={badgeRects(state)} />}
          {state.banner && <ModeBanner key={state.banner.count} from={state.banner.from} to={state.banner.to} />}
          <KeyCaps keys={keys} />
        </div>
      </div>
    </div>
  );
}
