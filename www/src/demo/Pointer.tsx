import { useEffect, useRef } from "react";
import { SCREEN } from "./geometry";
import type { DesktopState } from "./state";

/** Center of the `data-pointer` element in screen coordinates, undoing the scale the screen is drawn at. */
function targetCenter(screen: HTMLElement, target: string) {
  const element = screen.querySelector(`[data-pointer="${target}"]`);
  if (!element) return null;
  const screenBox = screen.getBoundingClientRect();
  const box = element.getBoundingClientRect();
  const scale = screenBox.width / SCREEN.w;
  return {
    x: (box.left + box.width / 2 - screenBox.left) / scale,
    y: (box.top + box.height / 2 - screenBox.top) / scale,
  };
}

/** A glassy dot that stands in for the mouse. It follows its target every frame, so it stays on a tile being dragged. */
export function Pointer({ pointer }: { pointer: DesktopState["pointer"] }) {
  const dot = useRef<HTMLDivElement>(null);
  const target = pointer?.target;

  useEffect(() => {
    const element = dot.current;
    const screen = element?.closest<HTMLElement>(".screen");
    if (!element || !screen || !target) return;
    let frame = requestAnimationFrame(function follow() {
      const at = targetCenter(screen, target);
      if (at) element.style.translate = `${at.x}px ${at.y}px`;
      frame = requestAnimationFrame(follow);
    });
    return () => cancelAnimationFrame(frame);
  }, [target]);

  const className = ["pointer", pointer && "visible", pointer?.pressed && "pressed"].filter(Boolean).join(" ");
  return <div ref={dot} className={className} />;
}
