import type { DesktopAction } from "./reducer";

export type Keys = { modifiers: string[]; key?: string };

export type Step = {
  /** What the keyboard shows; null lets go of every key. Left out, the keys stay as they were. */
  keys?: Keys | null;
  action?: DesktopAction;
  /** How long to stay on this step before the next one, in ms. */
  hold: number;
};

export type Chapter = { id: string; title: string; caption: string; steps: Step[] };

const NAVIGATE = ["⌃", "⌘"];
const MOVE = [...NAVIGATE, "⇧"];
const navigate = (key?: string): Keys => ({ modifiers: NAVIGATE, key });
const move = (key?: string): Keys => ({ modifiers: MOVE, key });

export const chapters: Chapter[] = [
  {
    id: "focus",
    title: "Focus",
    caption: "Navigate + ← → moves focus to the window on that side, as it sits on screen.",
    steps: [
      { hold: 900 },
      { keys: navigate("→"), action: { type: "focus", direction: "right" }, hold: 900 },
      { keys: navigate("←"), action: { type: "focus", direction: "left" }, hold: 900 },
      { keys: null, hold: 500 },
    ],
  },
  {
    id: "swap",
    title: "Swap",
    caption: "Add ⇧ to move the focused window instead. It trades places with its neighbour.",
    steps: [
      { keys: move("→"), action: { type: "move", direction: "right" }, hold: 1100 },
      { keys: move("←"), action: { type: "move", direction: "left" }, hold: 1100 },
      { keys: null, hold: 500 },
    ],
  },
  {
    id: "pick",
    title: "Pick a stage",
    caption: "Go up or down to walk through your stages. Let go to open one, or press Esc to stay.",
    steps: [
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 750 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 750 },
      { keys: navigate("↑"), action: { type: "pick", direction: "up" }, hold: 900 },
      { keys: null, action: { type: "confirmPick" }, hold: 1500 },
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
    id: "pull",
    title: "Pull a stage in",
    caption: "While a stage is picked, Move + → pulls it in. Let go and its windows join yours.",
    steps: [
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 700 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 800 },
      { keys: move("→"), action: { type: "grabPicked" }, hold: 900 },
      { keys: null, action: { type: "confirmPick" }, hold: 1500 },
    ],
  },
  {
    id: "resize",
    title: "Resize",
    caption: "Navigate with + or − grows and shrinks the focused window. Its neighbours make room, so tiles never overlap.",
    steps: [
      { keys: navigate("←"), action: { type: "focus", direction: "left" }, hold: 700 },
      { keys: navigate("+"), action: { type: "resize", direction: 1 }, hold: 600 },
      { keys: navigate("+"), action: { type: "resize", direction: 1 }, hold: 700 },
      { keys: navigate("−"), action: { type: "resize", direction: -1 }, hold: 900 },
      { keys: null, hold: 400 },
    ],
  },
  {
    id: "modes",
    title: "Tiling modes",
    caption: "Navigate + Space cycles the stage through Even, BSP, Messy, Custom and Off.",
    steps: [
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1400 },
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1400 },
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1400 },
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1000 },
      { keys: navigate("Space"), action: { type: "cycleMode" }, hold: 1300 },
      { keys: null, hold: 300 },
    ],
  },
  {
    id: "send-out",
    title: "Send a window out",
    caption: "At the edge next to Stage Manager, Move + ← sends the window to a stage of its own.",
    steps: [
      { keys: navigate("←"), action: { type: "focus", direction: "left" }, hold: 800 },
      { keys: move("←"), action: { type: "move", direction: "left" }, hold: 1600 },
      { keys: null, hold: 1000 },
    ],
  },
  {
    id: "full-screen",
    title: "Full screen",
    caption: "Turn off Don't cover Stage Manager to tile over the whole screen. The stages come back only while you pick one.",
    steps: [
      { action: { type: "openSettings" }, hold: 900 },
      { action: { type: "setLeaveRoomForStageManager", on: false }, hold: 1100 },
      { action: { type: "closeSettings" }, hold: 900 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 800 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 900 },
      { keys: null, action: { type: "confirmPick" }, hold: 2200 },
    ],
  },
];
