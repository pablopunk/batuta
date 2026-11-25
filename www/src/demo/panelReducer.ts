import type { UnitRect } from "./geometry";
import { evenGrid, type TilingMode } from "./layouts";
import { retiled, type DesktopState } from "./state";

/** What Batuta's menu bar panel and the demo's mouse can do. */
export type PanelAction =
  | { type: "openPanel" }
  | { type: "closePanel" }
  | { type: "setDefaultMode"; mode: TilingMode }
  | { type: "dragCustomTile"; index: number; rect: UnitRect }
  | { type: "releaseCustomTile" }
  | { type: "setLeaveRoomForStageManager"; on: boolean }
  | { type: "pointAt"; target: string }
  | { type: "pressPointer" }
  | { type: "releasePointer" }
  | { type: "hidePointer" };

export function panelReducer(state: DesktopState, action: PanelAction): DesktopState {
  const panel = state.panel;
  switch (action.type) {
    case "openPanel":
      return { ...state, panel: { ...panel, open: true } };
    case "closePanel":
      return { ...state, panel: { ...panel, open: false, activeTile: null } };
    case "setDefaultMode":
      return { ...state, defaultMode: action.mode };
    case "dragCustomTile": {
      const rects = [...(state.customLayouts[panel.windowCount] ?? evenGrid(panel.windowCount))];
      rects[action.index] = action.rect;
      return {
        ...state,
        customLayouts: { ...state.customLayouts, [panel.windowCount]: rects },
        panel: { ...panel, activeTile: action.index },
      };
    }
    case "releaseCustomTile":
      return { ...state, panel: { ...panel, activeTile: null } };
    case "pointAt":
      return { ...state, pointer: { target: action.target, pressed: false } };
    case "pressPointer":
      return state.pointer ? { ...state, pointer: { ...state.pointer, pressed: true } } : state;
    case "releasePointer":
      return state.pointer ? { ...state, pointer: { ...state.pointer, pressed: false } } : state;
    case "hidePointer":
      return { ...state, pointer: null };
    case "setLeaveRoomForStageManager": {
      const changed = { ...state, leaveRoomForStageManager: action.on };
      return { ...changed, current: retiled(changed, state.current.windows) };
    }
  }
}
