import { GAP, tileArea, type Rect } from "./geometry";
import type { AppId } from "./state";

const RESIZE_STEP = tileArea.w / 12;
const MINIMUM_WIDTH = 160;

const overlapsVertically = (a: Rect, b: Rect) => a.y < b.y + b.h && b.y < a.y + a.h;
const isLeftNeighbour = (candidate: Rect, of: Rect) =>
  Math.abs(candidate.x + candidate.w + GAP - of.x) < 2 && overlapsVertically(candidate, of);
const isRightNeighbour = (candidate: Rect, of: Rect) => isLeftNeighbour(of, candidate);

/** Neighbours give or take the same space, so tiles never overlap. */
export function resizedWithNeighbours(frames: Record<AppId, Rect>, focused: AppId, direction: 1 | -1) {
  const target = frames[focused];
  const entries = Object.entries(frames) as [AppId, Rect][];
  const left = entries.find(([, rect]) => isLeftNeighbour(rect, target));
  const right = entries.find(([, rect]) => isRightNeighbour(rect, target));
  if (!left && !right) return resizedAroundCenter(frames, focused, direction);

  const step = RESIZE_STEP * direction;
  const leftShare = left && right ? step / 2 : left ? step : 0;
  const rightShare = step - leftShare;
  const next = { ...frames, [focused]: { ...target, x: target.x - leftShare, w: target.w + step } };
  if (left) next[left[0]] = { ...left[1], w: left[1].w - leftShare };
  if (right) next[right[0]] = { ...right[1], x: right[1].x + rightShare, w: right[1].w - rightShare };
  const tooNarrow = Object.values(next).some((rect) => rect.w < MINIMUM_WIDTH);
  return tooNarrow ? frames : next;
}

export function resizedAroundCenter(frames: Record<AppId, Rect>, focused: AppId, direction: 1 | -1) {
  const target = frames[focused];
  const dw = RESIZE_STEP * direction;
  const dh = dw * (target.h / target.w);
  const width = Math.min(Math.max(target.w + dw, MINIMUM_WIDTH), tileArea.w);
  const height = Math.min(Math.max(target.h + dh, MINIMUM_WIDTH), tileArea.h);
  const x = Math.min(Math.max(target.x - (width - target.w) / 2, tileArea.x), tileArea.x + tileArea.w - width);
  const y = Math.min(Math.max(target.y - (height - target.h) / 2, tileArea.y), tileArea.y + tileArea.h - height);
  return { ...frames, [focused]: { x, y, w: width, h: height } };
}
