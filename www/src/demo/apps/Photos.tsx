import "./photos.css";

const SIDEBAR = ["Library", "Memories", "People", "Places", "Favourites", "Recents"];

const SCENES = [
  ["#87ceeb", "#e0f6ff", "#3a7d44", "#1f4d2b"],
  ["#ff9966", "#ffd194", "#2b2d42", "#14151f"],
  ["#4facfe", "#b6e3ff", "#d8c3a5", "#b08968"],
  ["#2c3e50", "#4ca1af", "#1b262c", "#0f171c"],
  ["#fbd3e9", "#fff1e6", "#6d9886", "#3f5e5a"],
  ["#89f7fe", "#66a6ff", "#0b3d91", "#072a63"],
  ["#f6d365", "#fda085", "#7a4e2d", "#4b2e1a"],
  ["#a1c4fd", "#c2e9fb", "#e6e6e6", "#b5b5b5"],
  ["#ff5f6d", "#ffc371", "#3d2c3e", "#1e1520"],
  ["#43cea2", "#a8edea", "#185a9d", "#0d3a66"],
  ["#d4fc79", "#96e6a1", "#4b7f52", "#2d4f33"],
  ["#cfd9df", "#e2ebf0", "#6b7b8c", "#47525e"],
];

const photo = ([skyTop, skyBottom, groundTop, groundBottom]: string[], index: number) => {
  const horizon = 45 + ((index * 7) % 20);
  const sun = index % 3 === 0 ? `radial-gradient(circle at ${30 + ((index * 13) % 50)}% ${horizon - 12}%, #fff8dc 0 6%, transparent 7%), ` : "";
  return `${sun}linear-gradient(180deg, ${skyTop} 0%, ${skyBottom} ${horizon}%, ${groundTop} ${horizon}%, ${groundBottom} 100%)`;
};

export const Photos = () => (
  <div className="app photos">
    <aside className="photos-sidebar">
      <div className="section">Photos</div>
      {SIDEBAR.map((item) => (
        <div key={item} className={item === "Library" ? "item active" : "item"}>{item}</div>
      ))}
    </aside>
    <section className="photos-main">
      <div className="photos-toolbar">
        <div className="segmented"><span>Years</span><span>Months</span><span className="on">All Photos</span></div>
      </div>
      <div className="day">Saturday · 21 Nov 2026</div>
      <div className="grid">
        {[...SCENES, ...SCENES.slice(0, 4)].map((scene, index) => (
          <div key={index} style={{ background: photo(scene, index) }} />
        ))}
      </div>
    </section>
  </div>
);
