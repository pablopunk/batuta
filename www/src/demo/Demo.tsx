import { Desktop } from "./Desktop";
import { chapters } from "./script";
import { usePlayer } from "./usePlayer";
import "./demo.css";

export default function Demo() {
  const { state, chapterIndex, keys, instant, jump } = usePlayer(chapters);
  const chapter = chapters[chapterIndex];

  return (
    <div className="demo">
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
    </div>
  );
}
