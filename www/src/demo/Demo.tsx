import { useCallback, useState, type MouseEvent } from "react";
import { ContextMenu, type MenuItem } from "./ContextMenu";
import { Desktop } from "./Desktop";
import { chapters } from "./script";
import { usePlayer } from "./usePlayer";
import "./demo.css";

export default function Demo() {
  const { state, chapterIndex, keys, instant, jump, playing, pause, resume } = usePlayer(chapters);
  const [menuAt, setMenuAt] = useState<{ x: number; y: number } | null>(null);
  const closeMenu = useCallback(() => setMenuAt(null), []);
  const chapter = chapters[chapterIndex];

  const openMenu = (event: MouseEvent) => {
    event.preventDefault();
    setMenuAt({ x: event.clientX, y: event.clientY });
  };

  const menuItems: MenuItem[] = [
    playing ? { label: "Pause demo", onSelect: pause } : { label: "Play demo", onSelect: resume },
    { label: "Restart demo", onSelect: () => jump(0) },
  ];

  return (
    <div className="demo" onContextMenu={openMenu}>
      <Desktop state={state} keys={keys} instant={instant} />
      <p className="caption" key={chapter.id}>{chapter.caption}</p>
      <ol className="chapters">
        {chapters.map((item, index) => (
          <li key={item.id}>
            <button className={index === chapterIndex ? "active" : undefined} onClick={() => jump(index)}>
              {item.title}
            </button>
          </li>
        ))}
      </ol>
      {menuAt && <ContextMenu at={menuAt} items={menuItems} onClose={closeMenu} />}
    </div>
  );
}
