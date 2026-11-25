import "./browser.css";

export const Browser = () => (
  <div className="app browser">
    <div className="browser-toolbar">
      <span className="nav">‹ ›</span>
      <div className="address">🔒 fieldnotes.blog/stages</div>
      <span className="nav">⇪ ＋</span>
    </div>
    <div className="page">
      <nav>
        <b>Fieldnotes</b>
        <span>Essays</span><span>Tools</span><span>About</span>
      </nav>
      <article>
        <small>Workflow · 6 min read</small>
        <h1>Keep every project on its own stage</h1>
        <p className="lede">One stage for code, one for mail, one for music. Switching context becomes a single key press.</p>
        <div className="figure" />
        <p>
          The trick is not to fight the window manager. Group what belongs together, give each group a home, and let the
          layout take care of itself. When a new window shows up, it should find its place without you dragging anything.
        </p>
        <p>
          After a week the keyboard is the fastest way around: left and right between windows, up and down between stages.
        </p>
      </article>
    </div>
  </div>
);
