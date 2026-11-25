import { useEffect } from "react";

export type MenuItem = { label: string; onSelect: () => void };

type Props = { at: { x: number; y: number }; items: MenuItem[]; onClose: () => void };

function useCloseOnOutsideInput(onClose: () => void) {
  useEffect(() => {
    const closeOnEscape = (event: KeyboardEvent) => event.key === "Escape" && onClose();
    window.addEventListener("pointerdown", onClose);
    window.addEventListener("scroll", onClose, true);
    window.addEventListener("resize", onClose);
    window.addEventListener("keydown", closeOnEscape);
    return () => {
      window.removeEventListener("pointerdown", onClose);
      window.removeEventListener("scroll", onClose, true);
      window.removeEventListener("resize", onClose);
      window.removeEventListener("keydown", closeOnEscape);
    };
  }, [onClose]);
}

/** A macOS-style context menu at the spot that was right-clicked. */
export function ContextMenu({ at, items, onClose }: Props) {
  useCloseOnOutsideInput(onClose);
  return (
    <div
      className="context-menu"
      role="menu"
      style={{ left: at.x, top: at.y }}
      onPointerDown={(event) => event.stopPropagation()}
      onContextMenu={(event) => event.preventDefault()}
    >
      {items.map((item) => (
        <button
          key={item.label}
          role="menuitem"
          onClick={() => {
            item.onSelect();
            onClose();
          }}
        >
          {item.label}
        </button>
      ))}
    </div>
  );
}
