import type { UnitRect } from "./geometry";
import { evenGrid, type TilingMode } from "./layouts";
import { retiled, type DesktopState } from "./state";

/** What Batuta's menu bar panel can do in the demo. */
export type PanelAction =
  | { type: "openPanel" }
  | { type: "closePanel" }
  | { type: "setDefaultMode"; mode: TilingMode }
  | { type: "dragCustomTile"; index: number; rect: UnitRect }
  | { type: "releaseCustomTile" }
  | { type: "setLeaveRoomForStageManager"; on: boolean };

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
    case "setLeaveRoomForStageManager": {
      const changed = { ...state, leaveRoomForStageManager: action.on };
      return { ...changed, current: retiled(changed, state.current.windows) };
    }
  }
}
