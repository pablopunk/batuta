import type { DesktopAction } from "./reducer";
import { MODE_SHORTCUT_KEYS, MODE_SHORTCUT_MODIFIERS, MOVE, NAVIGATE } from "./shortcuts";

export type Keys = { modifiers: string[]; key?: string };

export type Step = {
  /** What the keyboard shows; null lets go of every key. Left out, the keys stay as they were. */
  keys?: Keys | null;
  action?: DesktopAction | DesktopAction[];
  /** How long to stay on this step before the next one, in ms. */
  hold: number;
};

export type Chapter = { id: string; title: string; caption: string; steps: Step[] };

const navigate = (key?: string): Keys => ({ modifiers: NAVIGATE, key });
const move = (key?: string): Keys => ({ modifiers: MOVE, key });
const POINTER_TRAVEL = 600;
const PRESS = 140;

/** Moves the pointer onto a `data-pointer` element and clicks it; the click does `action`. */
const clickOn = (target: string, action: DesktopAction): Step[] => [
  { action: { type: "pointAt", target }, hold: POINTER_TRAVEL },
  { action: { type: "pressPointer" }, hold: PRESS },
  { action: [action, { type: "releasePointer" }], hold: 800 },
];

/** Presses on a `data-pointer` element and drags; each of `moves` is one stretch of the drag. */
const drag = (target: string, moves: DesktopAction[]): Step[] => [
  { action: { type: "pointAt", target }, hold: POINTER_TRAVEL },
  { action: { type: "pressPointer" }, hold: PRESS },
  ...moves.map((move): Step => ({ action: move, hold: 700 })),
  { action: [{ type: "releaseCustomTile" }, { type: "releasePointer" }], hold: 300 },
];

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
    title: "Shortcuts",
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
    title: "Pull in",
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
    title: "Send back",
    caption: "At the edge next to Stage Manager, Move + ← sends the window back to a stage of its own.",
    steps: [
      { keys: move("←"), action: { type: "move", direction: "left" }, hold: 1400 },
      { keys: null, hold: 400 },
    ],
  },
  {
    id: "pick",
    title: "Pick",
    caption: "Go up or down to walk through your stages. Let go to open one, or press Esc to stay.",
    steps: [
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 750 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 900 },
      { keys: null, action: { type: "confirmPick" }, hold: 1400 },
    ],
  },
  {
    id: "numbers",
    title: "Numbers",
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
    title: "Modes",
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
    title: "Layouts",
    caption: "Draw your own layout from the menu bar. Every stage with that many windows uses it.",
    steps: [
      ...clickOn("menubar-icon", { type: "openPanel" }),
      ...clickOn("mode-custom", { type: "setDefaultMode", mode: "custom" }),
      ...drag("tile-handle-1", [{ type: "dragCustomTile", index: 1, rect: { x: 0.5, y: 0, w: 0.4, h: 0.7 } }]),
      ...drag("tile-1", [{ type: "dragCustomTile", index: 1, rect: { x: 0.6, y: 0.15, w: 0.4, h: 0.7 } }]),
      ...drag("tile-handle-0", [{ type: "dragCustomTile", index: 0, rect: { x: 0, y: 0, w: 0.6, h: 1 } }]),
      ...clickOn("menubar-icon", { type: "closePanel" }),
      { action: { type: "hidePointer" }, hold: 300 },
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
      ...clickOn("menubar-icon", { type: "openPanel" }),
      ...clickOn("leave-room-toggle", { type: "setLeaveRoomForStageManager", on: false }),
      ...clickOn("menubar-icon", { type: "closePanel" }),
      { action: { type: "hidePointer" }, hold: 400 },
      { keys: navigate("↓"), action: { type: "pick", direction: "down" }, hold: 1000 },
      { keys: null, action: { type: "confirmPick" }, hold: 2200 },
    ],
  },
];
