import { APPS } from "./apps/index";
import type { Placement } from "./placements";
import type { AppId } from "./state";

type Props = { id: AppId; placement: Placement; focused: boolean };

const TrafficLights = ({ floating }: { floating?: boolean }) => (
  <span className={floating ? "lights floating" : "lights"}><i /><i /><i /></span>
);

export function Window({ id, placement, focused }: Props) {
  const app = APPS[id];
  const tilt = placement.inStrip ? 24 : 0;
  const className = ["window", focused && "focused", placement.inStrip && "in-strip", placement.hidden && "strip-hidden"]
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
      {app.title ? (
        <div className="titlebar">
          <TrafficLights />
          <span className="title">{app.title}</span>
        </div>
      ) : (
        <TrafficLights floating />
      )}
      <div className="content">{app.content}</div>
    </div>
  );
}
