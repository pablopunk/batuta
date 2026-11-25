import { center } from "./geometry";
import { nextMode, type TilingMode } from "./layouts";
import { panelReducer, type PanelAction } from "./panelReducer";
import { initialState, raised, retiled, stageFrames, stageMode, type AppId, type DesktopState, type Stage } from "./state";

export type Horizontal = "left" | "right";
export type Vertical = "up" | "down";

/** Everything the desktop can do. The automatic demo sends these on a timer; real input can send the same ones. */
export type DesktopAction =
  | { type: "focus"; direction: Horizontal }
  | { type: "move"; direction: Horizontal }
  | { type: "pick"; direction: Vertical }
  | { type: "grabPicked" }
  | { type: "confirmPick" }
  | { type: "cancelPick" }
  | { type: "showBadges" }
  | { type: "hideBadges" }
  | { type: "openStage"; index: number }
  | { type: "cycleMode" }
  | { type: "toggleMode"; mode: TilingMode }
  | { type: "openWindow"; app: AppId }
  | PanelAction
  | { type: "reset" }
  | { type: "load"; state: DesktopState };

export function desktopReducer(state: DesktopState, action: DesktopAction): DesktopState {
  switch (action.type) {
    case "focus":
      return focusNeighbour(state, action.direction);
    case "move":
      return moveFocused(state, action.direction);
    case "pick":
      return pick(state, action.direction);
    case "grabPicked":
      return state.picking ? { ...state, picking: { ...state.picking, pulling: true } } : state;
    case "confirmPick":
      if (!state.picking) return state;
      return state.picking.pulling ? pullIn(state, state.picking.index) : openStage(state, state.picking.index);
    case "cancelPick":
      return { ...state, picking: null };
    case "showBadges":
      return { ...state, badges: true };
    case "hideBadges":
      return { ...state, badges: false };
    case "openStage":
      return openStage(state, action.index);
    case "cycleMode":
      return withStageMode(state, { mode: nextMode(stageMode(state)) });
    case "toggleMode":
      return toggleMode(state, action.mode);
    case "openWindow":
      return openWindow(state, action.app);
    case "reset":
      return { ...initialState, flashCount: state.flashCount + 1 };
    case "load":
      return action.state;
    default:
      return panelReducer(state, action);
  }
}

const flashed = (state: DesktopState): DesktopState => ({ ...state, flashCount: state.flashCount + 1 });

function neighbour(state: DesktopState, direction: Horizontal): AppId | null {
  if (!state.focused) return null;
  const frames = stageFrames(state);
  const from = center(frames[state.focused]);
  const sign = direction === "right" ? 1 : -1;
  const candidates = state.current.windows
    .filter((id) => id !== state.focused)
    .map((id) => ({ id, at: center(frames[id]) }))
    .filter(({ at }) => (at.x - from.x) * sign > 1)
    .map(({ id, at }) => ({ id, score: Math.abs(at.x - from.x) + Math.abs(at.y - from.y) * 2 }))
    .sort((a, b) => a.score - b.score);
  return candidates[0]?.id ?? null;
}

function focusNeighbour(state: DesktopState, direction: Horizontal): DesktopState {
  const target = neighbour(state, direction);
  if (target) return flashed({ ...state, focused: target, zOrder: raised(state.zOrder, [target]) });
  return direction === "left" ? pick(state, "down") : state;
}

function moveFocused(state: DesktopState, direction: Horizontal): DesktopState {
  if (state.picking) return direction === "right" ? desktopReducer(state, { type: "grabPicked" }) : state;
  const focused = state.focused;
  if (!focused) return state;
  const target = neighbour(state, direction);
  if (!target) return direction === "left" ? sendOut(state, focused) : state;
  const windows = state.current.windows.map((id) => (id === focused ? target : id === target ? focused : id));
  const frames = state.current.frames && {
    ...state.current.frames,
    [focused]: state.current.frames[target],
    [target]: state.current.frames[focused],
  };
  return flashed({ ...state, current: { ...state.current, windows, frames } });
}

function sendOut(state: DesktopState, id: AppId): DesktopState {
  const remaining = state.current.windows.filter((window) => window !== id);
  const newStage: Stage = { id: `s${state.nextStageId}`, windows: [id] };
  const focused = remaining[0] ?? null;
  return flashed({
    ...state,
    current: retiled(state, remaining),
    strip: [newStage, ...state.strip],
    focused,
    zOrder: focused ? raised(state.zOrder, [focused]) : state.zOrder,
    nextStageId: state.nextStageId + 1,
  });
}

function pick(state: DesktopState, direction: Vertical): DesktopState {
  const count = state.strip.length;
  if (count === 0) return state;
  if (!state.picking) return { ...state, picking: { index: direction === "up" ? count - 1 : 0, pulling: false } };
  const step = direction === "up" ? -1 : 1;
  return { ...state, picking: { ...state.picking, index: (state.picking.index + step + count) % count } };
}

function openStage(state: DesktopState, index: number): DesktopState {
  const opened = state.strip[index];
  if (!opened) return state;
  const strip = [state.current, ...state.strip.filter((_, i) => i !== index)];
  const focused = opened.windows.at(-1) ?? null;
  return flashed({
    ...state,
    current: opened,
    strip,
    focused,
    zOrder: raised(state.zOrder, opened.windows),
    picking: null,
    badges: false,
  });
}

/** Pulled windows go first, on the side next to Stage Manager, so Move + ← can send them straight back. */
function pullIn(state: DesktopState, index: number): DesktopState {
  const pulled = state.strip[index];
  if (!pulled) return state;
  const windows = [...pulled.windows, ...state.current.windows];
  const focused = pulled.windows[0];
  return flashed({
    ...state,
    current: retiled(state, windows),
    strip: state.strip.filter((_, i) => i !== index),
    focused,
    zOrder: raised(state.zOrder, pulled.windows),
    picking: null,
  });
}

function openWindow(state: DesktopState, app: AppId): DesktopState {
  return flashed({
    ...state,
    current: retiled(state, [...state.current.windows, app]),
    focused: app,
    zOrder: raised(state.zOrder, [app]),
  });
}

function toggleMode(state: DesktopState, mode: TilingMode): DesktopState {
  const stage = state.current;
  const isOn = stage.mode === mode;
  return withStageMode(state, isOn ? { mode: stage.modeBeforeToggle } : { mode, modeBeforeToggle: stage.mode });
}

function withStageMode(state: DesktopState, change: Pick<Stage, "mode" | "modeBeforeToggle">): DesktopState {
  const changed = { ...state, current: { ...state.current, ...change, frames: undefined } };
  const from = stageMode(state);
  const to = stageMode(changed);
  const frames = to === "off" ? stageFrames(state) : undefined;
  return {
    ...changed,
    current: { ...changed.current, frames },
    banner: { from, to, count: (state.banner?.count ?? 0) + 1 },
  };
}
