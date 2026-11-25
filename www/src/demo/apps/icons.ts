import type { AppId } from "../state";

/** Made-up app icons: a squircle background and a short glyph. They are content, so they keep their colors in both themes. */
export type AppIcon = { background: string; glyph: string; color: string };

export const APP_ICONS: Record<AppId, AppIcon> = {
  editor: { background: "linear-gradient(160deg, #3b82f6, #1e3a8a)", glyph: "</>", color: "#fff" },
  terminal: { background: "linear-gradient(160deg, #3a3a40, #111114)", glyph: ">_", color: "#4ade80" },
  browser: { background: "linear-gradient(160deg, #38bdf8, #2563eb)", glyph: "◎", color: "#fff" },
  notes: { background: "linear-gradient(#facc15 0 28%, #fffbea 28%)", glyph: "≡", color: "#a3a3a3" },
  music: { background: "linear-gradient(160deg, #fb7185, #e11d48)", glyph: "♪", color: "#fff" },
  mail: { background: "linear-gradient(160deg, #60a5fa, #1d4ed8)", glyph: "✉", color: "#fff" },
  chat: { background: "linear-gradient(160deg, #4ade80, #16a34a)", glyph: "…", color: "#fff" },
  photos: {
    background: "conic-gradient(#f97316, #facc15, #4ade80, #38bdf8, #a78bfa, #f472b6, #f97316)",
    glyph: "",
    color: "#fff",
  },
};
