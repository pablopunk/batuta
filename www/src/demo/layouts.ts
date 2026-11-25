import type { UnitRect } from "./geometry";

export type TilingMode = "off" | "even" | "bsp" | "messy" | "custom";

export const TILING_MODES: TilingMode[] = ["off", "even", "bsp", "messy", "custom"];

export const MODE_LABELS: Record<TilingMode, string> = {
  off: "Off",
  even: "Even",
  bsp: "BSP",
  messy: "Messy",
  custom: "Custom",
};

export const nextMode = (mode: TilingMode) => TILING_MODES[(TILING_MODES.indexOf(mode) + 1) % TILING_MODES.length];

export function unitRects(count: number, mode: TilingMode): UnitRect[] {
  switch (mode) {
    case "off":
    case "even":
      return evenGrid(count);
    case "bsp":
      return binarySpacePartition(count);
    case "messy":
      return MESSY_LAYOUTS[count] ?? evenGrid(count);
    case "custom":
      return CUSTOM_LAYOUTS[count] ?? evenGrid(count);
  }
}

function evenGrid(count: number): UnitRect[] {
  if (count === 0) return [];
  const rowCount = count <= 3 ? 1 : Math.ceil(count / 3);
  const rowHeight = 1 / rowCount;
  const base = Math.floor(count / rowCount);
  const rowsWithExtraWindow = count % rowCount;
  return Array.from({ length: rowCount }).flatMap((_, row) => {
    const columns = row >= rowCount - rowsWithExtraWindow ? base + 1 : base;
    return Array.from({ length: columns }, (_, column) => ({
      x: column / columns,
      y: row * rowHeight,
      w: 1 / columns,
      h: rowHeight,
    }));
  });
}

function binarySpacePartition(count: number): UnitRect[] {
  if (count === 0) return [];
  let remaining: UnitRect = { x: 0, y: 0, w: 1, h: 1 };
  const rects: UnitRect[] = [];
  for (let index = 0; index < count - 1; index++) {
    const sideBySide = index % 2 === 0;
    const first = sideBySide
      ? { ...remaining, w: remaining.w / 2 }
      : { ...remaining, h: remaining.h / 2 };
    rects.push(first);
    remaining = sideBySide
      ? { ...remaining, x: first.x + first.w, w: first.w }
      : { ...remaining, y: first.y + first.h, h: first.h };
  }
  return [...rects, remaining];
}

const MESSY_LAYOUTS: Record<number, UnitRect[]> = {
  1: [{ x: 0.1, y: 0.05, w: 0.8, h: 0.9 }],
  2: [
    { x: 0.05, y: 0.05, w: 0.5, h: 0.8 },
    { x: 0.45, y: 0.15, w: 0.5, h: 0.8 },
  ],
  3: [
    { x: 0.05, y: 0.05, w: 0.5, h: 0.7 },
    { x: 0.45, y: 0.1, w: 0.5, h: 0.7 },
    { x: 0.3, y: 0.3, w: 0.5, h: 0.7 },
  ],
  4: [
    { x: 0.05, y: 0.05, w: 0.45, h: 0.5 },
    { x: 0.45, y: 0.05, w: 0.45, h: 0.5 },
    { x: 0.1, y: 0.4, w: 0.45, h: 0.5 },
    { x: 0.5, y: 0.45, w: 0.45, h: 0.5 },
  ],
  5: [
    { x: 0, y: 0, w: 0.5, h: 0.5 },
    { x: 0.5, y: 0, w: 0.5, h: 0.5 },
    { x: 0, y: 0.5, w: 0.35, h: 0.5 },
    { x: 0.35, y: 0.5, w: 0.35, h: 0.5 },
    { x: 0.7, y: 0.5, w: 0.3, h: 0.5 },
  ],
};

const CUSTOM_LAYOUTS: Record<number, UnitRect[]> = {
  2: [
    { x: 0, y: 0, w: 0.62, h: 1 },
    { x: 0.62, y: 0, w: 0.38, h: 1 },
  ],
  3: [
    { x: 0, y: 0, w: 0.58, h: 1 },
    { x: 0.58, y: 0, w: 0.42, h: 0.45 },
    { x: 0.58, y: 0.45, w: 0.42, h: 0.55 },
  ],
};
