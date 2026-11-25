import type { ReactNode } from "react";
import { Icon, type IconName } from "./icons";

export const Pill = ({ label, on }: { label: string; on: boolean }) => (
  <span className={on ? "pill on" : "pill"}>{label}</span>
);

export const Shortcut = ({ label }: { label: string }) => <span className="shortcut">{label}</span>;

export const SectionHeader = ({ title, icon }: { title: string; icon: IconName }) => (
  <div className="section-header">
    <Icon name={icon} size={13} />
    {title}
  </div>
);

export const ToggleRow = ({ title, subtitle, icon, on }: { title: string; subtitle: string; icon: IconName; on: boolean }) => (
  <div className="toggle-row">
    <span className="row-icon"><Icon name={icon} /></span>
    <div className="row-text">
      <b>{title}</b>
      <span>{subtitle}</span>
    </div>
    <i className={on ? "switch on" : "switch"} />
  </div>
);

export const CaptionedRow = ({ title, icon, caption, children }: { title: string; icon: IconName; caption: string; children?: ReactNode }) => (
  <div className="captioned-row">
    <div className="captioned-head">
      <span className="row-icon"><Icon name={icon} /></span>
      <b>{title}</b>
      {children}
    </div>
    <p>{caption}</p>
  </div>
);
