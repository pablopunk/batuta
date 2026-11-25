import type { Rect } from "./geometry";
import type { Highlight } from "./placements";
import type { Keys } from "./script";

const boxStyle = (rect: Rect) => ({ left: rect.x, top: rect.y, width: rect.w, height: rect.h });

/** Batuta's click-through frame: it flashes around the focused window and stays on a stage while picking. */
export function HighlightFrame({ highlight, flashCount }: { highlight: NonNullable<Highlight>; flashCount: number }) {
  return (
    <div className="highlight" style={boxStyle(highlight.rect)}>
      <div key={highlight.persistent ? "on" : flashCount} className={highlight.persistent ? "frame on" : "frame flash"} />
    </div>
  );
}

export function StageBadges({ rects }: { rects: Rect[] }) {
  return (
    <>
      {rects.map((rect, index) => (
        <div key={index} className="badge" style={{ left: rect.x + 2, top: rect.y + 2 }}>
          {index + 1}
        </div>
      ))}
    </>
  );
}

export function ModeBanner({ text, count }: { text: string; count: number }) {
  return (
    <div key={count} className="mode-banner">
      {text}
    </div>
  );
}

export function KeyCaps({ keys }: { keys: (Keys & { count: number }) | null }) {
  if (!keys) return <div className="keycaps" />;
  return (
    <div className="keycaps visible">
      {keys.modifiers.map((modifier) => (
        <kbd key={modifier}>{modifier}</kbd>
      ))}
      {keys.key && (
        <kbd key={`${keys.key}-${keys.count}`} className={keys.key.length > 1 ? "wide pressed" : "pressed"}>
          {keys.key}
        </kbd>
      )}
    </div>
  );
}
