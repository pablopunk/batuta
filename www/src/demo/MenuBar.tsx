const MENUS = ["File", "Edit", "View", "Window", "Help"];

const BatutaIcon = () => (
  <svg width="17" height="13" viewBox="0 0 17 13" aria-label="Batuta">
    <rect x="0.75" y="0.75" width="15.5" height="11.5" rx="3" fill="none" stroke="currentColor" strokeWidth="1.5" />
    <rect x="3" y="3" width="4" height="7" rx="1" fill="currentColor" />
  </svg>
);

const WifiIcon = () => (
  <svg width="16" height="12" viewBox="0 0 16 12" aria-hidden>
    <path d="M8 11.5 5.6 9a3.4 3.4 0 0 1 4.8 0z" fill="currentColor" />
    <path d="M3.4 6.8a6.5 6.5 0 0 1 9.2 0l-1.2 1.2a4.8 4.8 0 0 0-6.8 0z" fill="currentColor" />
    <path d="M1.2 4.6a9.6 9.6 0 0 1 13.6 0l-1.2 1.2a7.9 7.9 0 0 0-11.2 0z" fill="currentColor" />
  </svg>
);

const BatteryIcon = () => (
  <svg width="25" height="12" viewBox="0 0 25 12" aria-hidden>
    <rect x="0.5" y="0.5" width="21" height="11" rx="3" fill="none" stroke="currentColor" opacity="0.5" />
    <rect x="2" y="2" width="15" height="8" rx="1.5" fill="currentColor" />
    <path d="M23 4v4a2 2 0 0 0 0-4z" fill="currentColor" opacity="0.5" />
  </svg>
);

export function MenuBar({ appName, batutaMenuOpen }: { appName: string; batutaMenuOpen: boolean }) {
  return (
    <div className="menubar">
      <div className="menus">
        <b>{appName}</b>
        {MENUS.map((menu) => (
          <span key={menu}>{menu}</span>
        ))}
      </div>
      <div className="status">
        <span className={batutaMenuOpen ? "batuta-icon open" : "batuta-icon"}><BatutaIcon /></span>
        <BatteryIcon />
        <WifiIcon />
        <span>Wed 25 Nov 9:41</span>
      </div>
    </div>
  );
}
