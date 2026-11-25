export type Rect = { x: number; y: number; w: number; h: number };

export const SCREEN = { w: 1440, h: 900 };
export const MENU_BAR_HEIGHT = 28;
export const GAP = 12;
export const NATURAL_WINDOW = { w: 720, h: 480 };

const THUMB = { x: 20, w: 150, h: 104, spacing: 132 };
const THUMB_WINDOW_WIDTH = 112;
export const THUMB_SCALE = THUMB_WINDOW_WIDTH / NATURAL_WINDOW.w;

const visibleArea: Rect = {
  x: GAP,
  y: MENU_BAR_HEIGHT + GAP,
  w: SCREEN.w - GAP * 2,
  h: SCREEN.h - MENU_BAR_HEIGHT - GAP * 2,
};

const stripWidth = THUMB.x + THUMB.w - visibleArea.x + GAP;

const besideStageManager: Rect = {
  x: visibleArea.x + stripWidth,
  y: visibleArea.y,
  w: visibleArea.w - stripWidth,
  h: visibleArea.h,
};

export const tileArea = (leaveRoomForStageManager: boolean): Rect =>
  leaveRoomForStageManager ? besideStageManager : visibleArea;

export const STRIP_HIDE_DISTANCE = stripWidth + GAP;

export function thumbnailRect(index: number, stageCount: number): Rect {
  const stackHeight = stageCount * THUMB.spacing - (THUMB.spacing - THUMB.h);
  const top = visibleArea.y + (visibleArea.h - stackHeight) / 2;
  return { x: THUMB.x, y: top + index * THUMB.spacing, w: THUMB.w, h: THUMB.h };
}

export function thumbnailWindowOrigin(thumb: Rect, windowIndex: number, windowCount: number) {
  const stackOffset = { x: 12, y: 10 };
  const stackWidth = THUMB_WINDOW_WIDTH + stackOffset.x * (windowCount - 1);
  const stackHeight = NATURAL_WINDOW.h * THUMB_SCALE + stackOffset.y * (windowCount - 1);
  return {
    x: thumb.x + (thumb.w - stackWidth) / 2 + windowIndex * stackOffset.x,
    y: thumb.y + (thumb.h - stackHeight) / 2 + windowIndex * stackOffset.y,
  };
}

export type UnitRect = { x: number; y: number; w: number; h: number };

export function placeUnitRect(unit: UnitRect, area: Rect): Rect {
  const half = GAP / 2;
  const placement = { x: area.x - half, y: area.y - half, w: area.w + GAP, h: area.h + GAP };
  return {
    x: placement.x + unit.x * placement.w + half,
    y: placement.y + unit.y * placement.h + half,
    w: unit.w * placement.w - GAP,
    h: unit.h * placement.h - GAP,
  };
}

export const center = (r: Rect) => ({ x: r.x + r.w / 2, y: r.y + r.h / 2 });

export const padded = (r: Rect, by: number): Rect => ({ x: r.x - by, y: r.y - by, w: r.w + by * 2, h: r.h + by * 2 });
