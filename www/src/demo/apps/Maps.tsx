import "./maps.css";

const ROADS = [
  "M-20 120 C 120 90, 220 180, 420 140 S 700 60, 900 110",
  "M80 -20 C 110 120, 60 260, 140 420 S 180 600, 160 700",
  "M-20 320 C 200 300, 300 380, 520 330 S 760 260, 900 300",
  "M420 -20 C 400 140, 470 240, 440 420 S 420 600, 460 700",
];

export const Maps = () => (
  <div className="app maps">
    <svg className="map" viewBox="0 0 800 600" preserveAspectRatio="xMidYMid slice" aria-hidden>
      <rect width="800" height="600" className="land" />
      <path d="M560 -10 C 520 120, 640 220, 600 360 S 700 520, 820 560 L 820 -10 Z" className="water" />
      <ellipse cx="250" cy="230" rx="90" ry="60" className="park" />
      {ROADS.map((road) => <path key={road} d={road} className="road" />)}
      <circle cx="300" cy="250" r="9" className="pin" />
    </svg>
    <div className="map-search">⌕ Search Maps</div>
    <div className="map-card">
      <b>Coffee Lab</b>
      <span>Café · 6 min walk</span>
    </div>
  </div>
);
