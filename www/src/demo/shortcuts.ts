import type { TilingMode } from "./layouts";

export const NAVIGATE = ["⌃", "⌘"];
export const MOVE = [...NAVIGATE, "⇧"];
export const MODE_SHORTCUT_MODIFIERS = ["⌃", "⌥", "⌘"];

/** Shortcuts that toggle one mode on the current stage. The app has none by default; the demo sets two. */
export const MODE_SHORTCUT_KEYS: Partial<Record<TilingMode, string>> = { even: "U", messy: "I" };
