import type { DesktopAction } from "./reducer";
import { MODE_SHORTCUT_KEYS, MODE_SHORTCUT_MODIFIERS, MOVE, NAVIGATE } from "./shortcuts";

export type Keys = { modifiers: string[]; key?: string };

export type Step = {
  /** What the keyboard shows; null lets go of every key. Left out, the keys stay as they were. */
  keys?: Keys | null;
  action?: DesktopAction;
  /** How long to stay on this step before the next one, in ms. */
  hold: number;
};

export type Chapter = { id: string; title: string; caption: string; steps: Step[] };

const navigate = (key?: string): Keys => ({ modifiers: NAVIGATE, key });
const move = (key?: string): Keys => ({ modifiers: MOVE, key });
const toggleEven: Keys = { modifiers: MODE_SHORTCUT_MODIFIERS, key: MODE_SHORTCUT_KEYS.even };

export const chapters: Chapter[] = [
  {
    id: "messy",
    title: "Messy",
    caption: "Batuta tiles every stage for you. This one is Messy: loose, hand-drawn layouts where windows can overlap.",
    steps: [{ hold: 2200 }],
  },
  {
    id: "mode-shortcut",
    title: "Mode shortcuts",
    caption: "Give a mode its own shortcut to switch the stage to it. Press it again to go back.",
    steps: [
      { keys: toggleEven, action: { type: "toggleMode", mode: "even" }, hold: 1500 },
      { keys: toggleEven, action: { type: "toggleMode", mode: "even" }, hold: 1500 },
      { keys: null, hold: 300 },
    ],
  },
  {
    id: "focus",
    title: "Focus",
    caption: "Navigate + ← → moves focus to the window on that side, as it sits on screen.",
    steps: [
      { keys: navigate("→"), action: { type: "focus", direction: "right" }, hold: 800 },
      { keys: navigate("←"), action: { type: "focus", direction: "left" }, hold: 800 },
      { keys: navigate("←"), action: { type: "focus", direction: "left" }, hold: 800 },
      { keys: null, hold: 400 },
    ],
  },
  {
    id: "swap",
    title: "Swap",
    caption: "Add ⇧ to move the focused window instead. It trades places with its neighbour.",
    steps: [
      { keys: move("→"), action: { type: "move", direction: "right" }, hold: 1100 },
      { keys: move("←"), action: { type: "move", direction: "left" }, hold: 1100 },
      { keys: null, hold: 400 },
    ],
  },
  {
    id: "pull",
    title: "Pull a stage in",
    caption: "Pick a stage with Navigate + ↓, then Move + → pulls it in. Let go and its windows join yours.",
    steps: [
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 700 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 800 },
      { keys: move("→"), action: { type: "grabPicked" }, hold: 900 },
      { keys: null, action: { type: "confirmPick" }, hold: 1400 },
    ],
  },
  {
    id: "send-back",
    title: "Send it back",
    caption: "At the edge next to Stage Manager, Move + ← sends the window back to a stage of its own.",
    steps: [
      { keys: move("←"), action: { type: "move", direction: "left" }, hold: 1400 },
      { keys: null, hold: 400 },
    ],
  },
  {
    id: "pick",
    title: "Pick a stage",
    caption: "Go up or down to walk through your stages. Let go to open one, or press Esc to stay.",
    steps: [
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 750 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 900 },
      { keys: null, action: { type: "confirmPick" }, hold: 1400 },
    ],
  },
  {
    id: "numbers",
    title: "Jump by number",
    caption: "Hold Navigate and every stage gets a number. Press one to go straight there.",
    steps: [
      { keys: navigate(), hold: 400 },
      { action: { type: "showBadges" }, hold: 1100 },
      { keys: navigate("1"), action: { type: "openStage", index: 0 }, hold: 1300 },
      { keys: null, hold: 400 },
    ],
  },
  {
    id: "modes",
    title: "Tiling modes",
    caption: "Navigate + Space cycles the stage through every mode: Custom, Off, Even, BSP and Messy.",
    steps: [
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1300 },
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1000 },
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1300 },
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1300 },
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1300 },
      { keys: null, hold: 300 },
    ],
  },
  {
    id: "custom",
    title: "Draw a layout",
    caption: "Draw your own layout from the menu bar. Every stage with that many windows uses it.",
    steps: [
      { action: { type: "openPanel" }, hold: 900 },
      { action: { type: "setDefaultMode", mode: "custom" }, hold: 1000 },
      { action: { type: "dragCustomTile", index: 1, rect: { x: 0.5, y: 0, w: 0.4, h: 0.7 } }, hold: 700 },
      { action: { type: "dragCustomTile", index: 1, rect: { x: 0.6, y: 0.15, w: 0.4, h: 0.7 } }, hold: 700 },
      { action: { type: "dragCustomTile", index: 0, rect: { x: 0, y: 0, w: 0.6, h: 1 } }, hold: 700 },
      { action: { type: "releaseCustomTile" }, hold: 700 },
      { action: { type: "closePanel" }, hold: 600 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 500 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 500 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 800 },
      { keys: null, action: { type: "confirmPick" }, hold: 2000 },
    ],
  },
  {
    id: "full-screen",
    title: "Full screen",
    caption: "Turn off Don't cover Stage Manager to tile over the whole screen. The stages come back only while you pick one.",
    steps: [
      { action: { type: "openPanel" }, hold: 900 },
      { action: { type: "setLeaveRoomForStageManager", on: false }, hold: 1100 },
      { action: { type: "closePanel" }, hold: 900 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 1000 },
      { keys: null, action: { type: "confirmPick" }, hold: 2200 },
    ],
  },
];
