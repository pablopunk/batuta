import { placeUnitRect, tileArea, type Rect } from "./geometry";
import { unitRects, type TilingMode } from "./layouts";

export type AppId = "editor" | "terminal" | "browser" | "notes" | "music" | "mail" | "chat" | "photos";

export type Stage = {
  id: string;
  windows: AppId[];
  mode: TilingMode;
  /** Set when windows were sized by hand or the mode is Off; otherwise the mode's layout decides. */
  frames?: Partial<Record<AppId, Rect>>;
};

export type Picking = { index: number; pulling: boolean };

export type DesktopState = {
  current: Stage;
  strip: Stage[];
  focused: AppId | null;
  zOrder: AppId[];
  picking: Picking | null;
  badges: boolean;
  flashCount: number;
  banner: { from: TilingMode; to: TilingMode; count: number } | null;
  /** Off tiles over the whole screen; Stage Manager then hides its strip until Batuta reveals it to pick a stage. */
  leaveRoomForStageManager: boolean;
  settingsOpen: boolean;
  nextStageId: number;
};

export const initialState: DesktopState = {
  current: { id: "s0", windows: ["editor", "terminal"], mode: "even" },
  strip: [
    { id: "s1", windows: ["browser", "notes"], mode: "even" },
    { id: "s2", windows: ["music"], mode: "even" },
    { id: "s3", windows: ["mail", "chat"], mode: "even" },
    { id: "s4", windows: ["photos"], mode: "even" },
  ],
  focused: "editor",
  zOrder: ["browser", "notes", "music", "mail", "chat", "photos", "terminal", "editor"],
  picking: null,
  badges: false,
  flashCount: 0,
  banner: null,
  leaveRoomForStageManager: true,
  settingsOpen: false,
  nextStageId: 5,
};

export const stageArea = (state: DesktopState) => tileArea(state.leaveRoomForStageManager);

export const currentFrames = (state: DesktopState) => stageFrames(state.current, stageArea(state));

export function stageFrames(stage: Stage, area: Rect): Record<AppId, Rect> {
  const layout = unitRects(stage.windows.length, stage.mode).map((unit) => placeUnitRect(unit, area));
  return Object.fromEntries(
    stage.windows.map((id, index) => [id, stage.frames?.[id] ?? layout[index]]),
  ) as Record<AppId, Rect>;
}

export function retiled(stage: Stage, windows: AppId[], area: Rect): Stage {
  if (stage.mode !== "off") return { ...stage, windows, frames: undefined };
  const evenFrames = stageFrames({ ...stage, windows, mode: "even", frames: undefined }, area);
  const frames = Object.fromEntries(windows.map((id) => [id, stage.frames?.[id] ?? evenFrames[id]]));
  return { ...stage, windows, frames };
}

export const stripIsHidden = (state: DesktopState) => !state.leaveRoomForStageManager && !state.picking;

export const raised = (zOrder: AppId[], ids: AppId[]) => [...zOrder.filter((id) => !ids.includes(id)), ...ids];
