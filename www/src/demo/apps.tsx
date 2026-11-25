import type { ReactNode } from "react";
import type { AppId } from "./state";
import "./apps.css";

type App = { name: string; title: string; dark: boolean; content: ReactNode };

const CODE_LINES: [number, number, string][] = [
  [0, 34, "#c678dd"], [0, 52, "#61afef"], [1, 40, "#e5c07b"], [1, 62, "#98c379"], [2, 28, "#abb2bf"],
  [2, 46, "#61afef"], [1, 20, "#c678dd"], [0, 10, "#abb2bf"], [0, 0, ""], [0, 44, "#c678dd"],
  [1, 58, "#98c379"], [1, 36, "#e06c75"], [2, 50, "#61afef"], [2, 30, "#abb2bf"], [1, 14, "#c678dd"],
  [0, 10, "#abb2bf"], [0, 0, ""], [0, 38, "#c678dd"], [1, 54, "#e5c07b"], [1, 26, "#98c379"],
];

const Editor = () => (
  <div className="app editor">
    <aside>
      {["Sources", "AppDelegate", "HotkeyTap", "StageStrip", "Tiling", "WindowAnimator"].map((file, i) => (
        <div key={file} className={i === 2 ? "file active" : "file"} style={{ paddingLeft: i === 0 || i === 4 ? 8 : 20 }}>
          {file}
        </div>
      ))}
    </aside>
    <div className="code">
      {CODE_LINES.map(([indent, width, color], i) => (
        <div key={i} className="line">
          <span className="number">{i + 1}</span>
          <span className="bar" style={{ marginLeft: indent * 18, width: `${width}%`, background: color }} />
        </div>
      ))}
    </div>
  </div>
);

const Terminal = () => (
  <div className="app terminal">
    <div><b>~/batuta</b> <i>main</i> $ make run</div>
    <div className="dim">Building for debugging...</div>
    <div className="dim">[42/42] Linking Batuta</div>
    <div className="ok">Build complete! (3.81s)</div>
    <div><b>~/batuta</b> <i>main</i> $ git log --oneline -3</div>
    <div><span className="sha">08c33fe</span> Wrap around inside the stage picker</div>
    <div><span className="sha">1463be8</span> Custom one-window layout for Messy</div>
    <div><span className="sha">d6f0f55</span> Treat small moves as the layout</div>
    <div><b>~/batuta</b> <i>main</i> $ <span className="cursor" /></div>
  </div>
);

const Browser = () => (
  <div className="app browser">
    <div className="url">batuta.app</div>
    <div className="hero" />
    <div className="cards">
      <div /><div /><div />
    </div>
    <div className="text"><div /><div /><div style={{ width: "60%" }} /></div>
  </div>
);

const Notes = () => (
  <div className="app notes">
    <h4>Ideas</h4>
    {["Stage per project", "Editor + terminal side by side", "Music in its own stage", "Mail only after lunch", "Try BSP for 4+ windows"].map((note) => (
      <div key={note} className="note">{note}</div>
    ))}
  </div>
);

const ALBUM_COLORS = ["#f97316", "#8b5cf6", "#06b6d4", "#ec4899", "#22c55e", "#eab308"];

const Music = () => (
  <div className="app music">
    <div className="albums">
      {ALBUM_COLORS.map((color) => (
        <div key={color} style={{ background: `linear-gradient(135deg, ${color}, #111)` }} />
      ))}
    </div>
    <div className="player">
      <div className="art" />
      <div className="progress"><div /></div>
    </div>
  </div>
);

const Mail = () => (
  <div className="app mail">
    <div className="list">
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <div key={i} className={i === 0 ? "message active" : "message"}>
          <div className="from" /><div className="subject" />
        </div>
      ))}
    </div>
    <div className="read"><div className="headline" /><div /><div /><div style={{ width: "70%" }} /></div>
  </div>
);

const Chat = () => (
  <div className="app chat">
    <div className="bubble them">ship it?</div>
    <div className="bubble me">one more tiling mode</div>
    <div className="bubble them">you said that yesterday</div>
    <div className="bubble me">this one is messy on purpose</div>
  </div>
);

const PHOTO_HUES = [10, 40, 200, 280, 150, 330, 20, 190, 260, 60, 120, 350];

const Photos = () => (
  <div className="app photos">
    {PHOTO_HUES.map((hue) => (
      <div key={hue} style={{ background: `linear-gradient(160deg, hsl(${hue} 80% 70%), hsl(${hue + 40} 70% 40%))` }} />
    ))}
  </div>
);

export const APPS: Record<AppId, App> = {
  editor: { name: "Editor", title: "HotkeyTap.swift", dark: true, content: <Editor /> },
  terminal: { name: "Terminal", title: "~/batuta — zsh", dark: true, content: <Terminal /> },
  browser: { name: "Browser", title: "Batuta", dark: false, content: <Browser /> },
  notes: { name: "Notes", title: "Ideas", dark: false, content: <Notes /> },
  music: { name: "Music", title: "Listen Now", dark: true, content: <Music /> },
  mail: { name: "Mail", title: "Inbox", dark: false, content: <Mail /> },
  chat: { name: "Chat", title: "Messages", dark: false, content: <Chat /> },
  photos: { name: "Photos", title: "Library", dark: false, content: <Photos /> },
};
