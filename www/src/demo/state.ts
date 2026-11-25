import { placeUnitRect, tileArea, type Rect, type UnitRect } from "./geometry";
import { unitRects, type CustomLayouts, type TilingMode } from "./layouts";

export type AppId = "editor" | "terminal" | "browser" | "notes" | "music" | "mail" | "chat" | "photos";

export type Stage = {
  id: string;
  windows: AppId[];
  /** Set by a mode shortcut or the cycle shortcut; until then the stage follows the default mode from the panel. */
  mode?: TilingMode;
  /** What a mode shortcut goes back to when pressed again. */
  modeBeforeToggle?: TilingMode;
  /** Set when windows were sized by hand or the mode is Off; otherwise the mode's layout decides. */
  frames?: Partial<Record<AppId, Rect>>;
};

export type Picking = { index: number; pulling: boolean };

/** Batuta's menu bar panel, open on its Tiling tab. */
export type Panel = { open: boolean; windowCount: number; activeTile: number | null };

export type DesktopState = {
  current: Stage;
  strip: Stage[];
  focused: AppId | null;
  zOrder: AppId[];
  picking: Picking | null;
  badges: boolean;
  flashCount: number;
  banner: { from: TilingMode; to: TilingMode; count: number } | null;
  defaultMode: TilingMode;
  customLayouts: CustomLayouts;
  /** Off tiles over the whole screen; Stage Manager then hides its strip until Batuta reveals it to pick a stage. */
  leaveRoomForStageManager: boolean;
  panel: Panel;
  nextStageId: number;
};

export const initialState: DesktopState = {
  current: { id: "s0", windows: ["editor", "terminal", "browser"] },
  strip: [
    { id: "s1", windows: ["notes"] },
    { id: "s2", windows: ["music"] },
    { id: "s3", windows: ["mail", "chat"] },
    { id: "s4", windows: ["photos"] },
  ],
  focused: "editor",
  zOrder: ["notes", "music", "mail", "chat", "photos", "browser", "terminal", "editor"],
  picking: null,
  badges: false,
  flashCount: 0,
  banner: null,
  defaultMode: "messy",
  customLayouts: {},
  leaveRoomForStageManager: true,
  panel: { open: false, windowCount: 2, activeTile: null },
  nextStageId: 5,
};

export const stageArea = (state: DesktopState) => tileArea(state.leaveRoomForStageManager);

export const stageMode = (state: DesktopState, stage: Stage = state.current) => stage.mode ?? state.defaultMode;

export const modeRects = (state: DesktopState, count: number, mode: TilingMode): UnitRect[] =>
  unitRects(count, mode, state.customLayouts);

export function stageFrames(state: DesktopState, stage: Stage = state.current): Record<AppId, Rect> {
  const area = stageArea(state);
  const layout = modeRects(state, stage.windows.length, stageMode(state, stage)).map((unit) => placeUnitRect(unit, area));
  return Object.fromEntries(
    stage.windows.map((id, index) => [id, stage.frames?.[id] ?? layout[index]]),
  ) as Record<AppId, Rect>;
}

/** The current stage with new windows. Off keeps every window where it was; other modes lay them all out again. */
export function retiled(state: DesktopState, windows: AppId[]): Stage {
  const stage = state.current;
  if (stageMode(state) !== "off") return { ...stage, windows, frames: undefined };
  const evenFrames = stageFrames(state, { ...stage, windows, mode: "even", frames: undefined });
  const frames = Object.fromEntries(windows.map((id) => [id, stage.frames?.[id] ?? evenFrames[id]]));
  return { ...stage, windows, frames };
}

export const stripIsHidden = (state: DesktopState) => !state.leaveRoomForStageManager && !state.picking;

export const raised = (zOrder: AppId[], ids: AppId[]) => [...zOrder.filter((id) => !ids.includes(id)), ...ids];
