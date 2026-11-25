import type { ReactNode } from "react";
import type { AppId } from "../state";

/** Made-up app icons: a squircle background and an SVG glyph on a 24-unit grid. They are content, so they keep their colors in both themes. */
export type AppIcon = { background: string; glyph: ReactNode };

const stroke = (color: string, width = 2) => ({
  fill: "none",
  stroke: color,
  strokeWidth: width,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
});

const PETAL_COLORS = ["#f97316", "#facc15", "#4ade80", "#38bdf8", "#a78bfa", "#f472b6"];

export const APP_ICONS: Record<AppId, AppIcon> = {
  editor: {
    background: "linear-gradient(160deg, #3b82f6, #1e3a8a)",
    glyph: <path d="M8 7l-5 5 5 5M16 7l5 5-5 5M13.5 5l-3 14" {...stroke("#fff")} />,
  },
  terminal: {
    background: "linear-gradient(160deg, #3a3a40, #111114)",
    glyph: <path d="M5 7l5 5-5 5M12 18h7" {...stroke("#4ade80", 2.4)} />,
  },
  browser: {
    background: "linear-gradient(160deg, #38bdf8, #2563eb)",
    glyph: (
      <>
        <circle cx="12" cy="12" r="9" {...stroke("#fff")} />
        <path d="M15.5 8.5l-2 5-5 2 2-5z" fill="#fff" />
      </>
    ),
  },
  notes: {
    background: "linear-gradient(#facc15 0 26%, #fffbea 26%)",
    glyph: <path d="M5 11h14M5 15h14M5 19h9" {...stroke("#b8b8b8", 1.6)} />,
  },
  music: {
    background: "linear-gradient(160deg, #fb7185, #e11d48)",
    glyph: (
      <>
        <path d="M9 17V5l10-2v12" {...stroke("#fff")} />
        <circle cx="6.5" cy="17.5" r="2.5" fill="#fff" />
        <circle cx="16.5" cy="15.5" r="2.5" fill="#fff" />
      </>
    ),
  },
  mail: {
    background: "linear-gradient(160deg, #60a5fa, #1d4ed8)",
    glyph: (
      <>
        <rect x="3" y="6" width="18" height="12" rx="2" fill="#fff" />
        <path d="M3.5 7l8.5 6.5L20.5 7" {...stroke("#1d4ed8", 1.6)} />
      </>
    ),
  },
  chat: {
    background: "linear-gradient(160deg, #4ade80, #16a34a)",
    glyph: <path d="M12 4c5 0 9 3.1 9 7s-4 7-9 7c-1 0-2-.1-2.9-.4L4.5 20l1.2-3.6C4 15 3 13.1 3 11c0-3.9 4-7 9-7z" fill="#fff" />,
  },
  photos: {
    background: "linear-gradient(#ffffff, #f1f1f4)",
    glyph: (
      <>
        {PETAL_COLORS.map((color, index) => (
          <ellipse key={color} cx="12" cy="7" rx="3" ry="5" fill={color} opacity="0.85" transform={`rotate(${index * 60} 12 12)`} />
        ))}
      </>
    ),
  },
};
