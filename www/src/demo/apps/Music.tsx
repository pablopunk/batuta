import { ALBUMS } from "./albumArt";
import "./music.css";

const SIDEBAR: [section: string | null, items: string[]][] = [
  [null, ["Listen Now", "Browse", "Radio"]],
  ["Library", ["Recently Added", "Artists", "Albums", "Songs"]],
  ["Playlists", ["Deep Focus", "Night Coding", "Sunday Morning"]],
];

const NOW_PLAYING = ALBUMS[0];
const TOP_PICKS = ALBUMS.slice(1, 5);
const RECENTLY_PLAYED = ALBUMS.slice(4, 8);

export function Music() {
  return (
    <div className="app music">
      <aside className="music-sidebar">
        <div className="search">⌕ Search</div>
        {SIDEBAR.map(([section, items]) => (
          <div key={section ?? "main"} className="group">
            {section && <div className="section">{section}</div>}
            {items.map((item) => (
              <div key={item} className={item === "Listen Now" ? "item active" : "item"}>
                <span className="dot" />
                {item}
              </div>
            ))}
          </div>
        ))}
      </aside>
      <section className="music-main">
        <div className="player-bar">
          <div className="transport">
            <span>⇄</span><span>⏮</span><span className="play">⏸</span><span>⏭</span><span>↻</span>
          </div>
          <div className="lcd">
            <div className="lcd-art" style={{ background: NOW_PLAYING.art }} />
            <div className="lcd-text">
              <b>Glass Harbor</b>
              <span>{NOW_PLAYING.artist} — {NOW_PLAYING.title}</span>
              <div className="scrubber"><div /></div>
            </div>
          </div>
          <div className="volume"><div /></div>
        </div>
        <div className="music-scroll">
          <h2>Listen Now</h2>
          <h3>Top Picks</h3>
          <div className="cards">
            {TOP_PICKS.map((album) => (
              <div key={album.title} className="card">
                <div className="cover" style={{ background: album.art }} />
                <b>{album.title}</b>
                <span>{album.artist}</span>
              </div>
            ))}
          </div>
          <h3 className="recent">Recently Played</h3>
          <div className="cards small">
            {RECENTLY_PLAYED.map((album) => (
              <div key={album.title} className="card">
                <div className="cover" style={{ background: album.art }} />
                <b>{album.title}</b>
                <span>{album.artist}</span>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}
