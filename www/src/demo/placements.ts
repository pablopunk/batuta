import { NATURAL_WINDOW, STRIP_HIDE_DISTANCE, THUMB_SCALE, padded, thumbnailRect, thumbnailWindowOrigin, type Rect } from "./geometry";
import { stageFrames, stripIsHidden, type AppId, type DesktopState } from "./state";

export type Placement = Rect & { scale: number; inStrip: boolean; hidden?: boolean; z: number };

const PULL_DISTANCE = 120;
const PULL_ZOOM = 1.4;
const HIGHLIGHT_PADDING = 6;

export function windowPlacements(state: DesktopState): Record<AppId, Placement> {
  const placements = {} as Record<AppId, Placement>;
  const frames = stageFrames(state);
  const hidden = stripIsHidden(state);
  const stripCoversWindows = !state.leaveRoomForStageManager;
  for (const id of state.current.windows) {
    placements[id] = { ...frames[id], scale: 1, inStrip: false, z: 100 + state.zOrder.indexOf(id) };
  }
  state.strip.forEach((stage, stageIndex) => {
    const thumb = thumbnailRect(stageIndex, state.strip.length);
    const isPulled = state.picking?.pulling && state.picking.index === stageIndex;
    stage.windows.forEach((id, windowIndex) => {
      const origin = thumbnailWindowOrigin(thumb, windowIndex, stage.windows.length);
      placements[id] = {
        x: origin.x + (isPulled ? PULL_DISTANCE : 0) - (hidden ? STRIP_HIDE_DISTANCE : 0),
        y: origin.y,
        w: NATURAL_WINDOW.w,
        h: NATURAL_WINDOW.h,
        scale: THUMB_SCALE * (isPulled ? PULL_ZOOM : 1),
        inStrip: !isPulled,
        hidden,
        z: isPulled ? 500 + windowIndex : (stripCoversWindows ? 400 : 10) + windowIndex,
      };
    });
  });
  return placements;
}

export type StripIconRow = { stageId: string; apps: AppId[]; x: number; y: number; z: number; hidden: boolean };

const ICON_OVERHANG = { x: -6, y: 18 };

export function stripIconRows(state: DesktopState): StripIconRow[] {
  const hidden = stripIsHidden(state);
  return state.strip
    .map((stage, index) => ({ stage, index, thumb: thumbnailRect(index, state.strip.length) }))
    .filter(({ index }) => !(state.picking?.pulling && state.picking.index === index))
    .map(({ stage, thumb }) => ({
      stageId: stage.id,
      apps: stage.windows,
      x: thumb.x + ICON_OVERHANG.x - (hidden ? STRIP_HIDE_DISTANCE : 0),
      y: thumb.y + thumb.h - ICON_OVERHANG.y,
      z: state.leaveRoomForStageManager ? 60 : 460,
      hidden,
    }));
}

export type Highlight = { rect: Rect; persistent: boolean } | null;

export function highlight(state: DesktopState): Highlight {
  if (state.picking) {
    return { rect: padded(thumbnailRect(state.picking.index, state.strip.length), HIGHLIGHT_PADDING), persistent: true };
  }
  if (!state.focused) return null;
  return { rect: padded(stageFrames(state)[state.focused], HIGHLIGHT_PADDING), persistent: false };
}

export const badgeRects = (state: DesktopState) =>
  state.strip.slice(0, 9).map((_, index) => thumbnailRect(index, state.strip.length));
