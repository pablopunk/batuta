import type { ReactNode } from "react";
import { Icon, type IconName } from "./icons";

export const Pill = ({ label, on, pointer }: { label: string; on: boolean; pointer?: string }) => (
  <span data-pointer={pointer} className={on ? "pill on" : "pill"}>{label}</span>
);

export const Shortcut = ({ label }: { label: string }) => <span className="shortcut">{label}</span>;

export const SectionHeader = ({ title, icon }: { title: string; icon: IconName }) => (
  <div className="section-header">
    <Icon name={icon} size={13} />
    {title}
  </div>
);

type ToggleRowProps = { title: string; subtitle: string; icon: IconName; on: boolean; pointer?: string };

export const ToggleRow = ({ title, subtitle, icon, on, pointer }: ToggleRowProps) => (
  <div className="toggle-row">
    <span className="row-icon"><Icon name={icon} /></span>
    <div className="row-text">
      <b>{title}</b>
      <span>{subtitle}</span>
    </div>
    <i data-pointer={pointer} className={on ? "switch on" : "switch"} />
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
