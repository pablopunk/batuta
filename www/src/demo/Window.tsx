import { APPS } from "./apps";
import type { Placement } from "./placements";
import type { AppId } from "./state";

type Props = { id: AppId; placement: Placement; focused: boolean };

export function Window({ id, placement, focused }: Props) {
  const app = APPS[id];
  const tilt = placement.inStrip ? 24 : 0;
  const className = ["window", app.dark && "dark", focused && "focused", placement.inStrip && "in-strip"]
    .filter(Boolean)
    .join(" ");
  return (
    <div
      className={className}
      style={{
        left: placement.x,
        top: placement.y,
        width: placement.w,
        height: placement.h,
        zIndex: placement.z,
        transform: `perspective(900px) rotateY(${tilt}deg) scale(${placement.scale})`,
      }}
    >
      <div className="titlebar">
        <span className="lights"><i /><i /><i /></span>
        <span className="title">{app.title}</span>
      </div>
      <div className="content">{app.content}</div>
    </div>
  );
}
