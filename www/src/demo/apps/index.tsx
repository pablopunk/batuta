import type { ReactNode } from "react";
import "./app.css";
import type { AppId } from "../state";
import { Browser } from "./Browser";
import { Calendar } from "./Calendar";
import { Chat } from "./Chat";
import { Editor } from "./Editor";
import { Mail } from "./Mail";
import { Maps } from "./Maps";
import { Music } from "./Music";
import { Notes } from "./Notes";
import { Photos } from "./Photos";
import { Terminal } from "./Terminal";
import { Weather } from "./Weather";

/** `title` draws a classic title bar; without it the app draws its own top and the traffic lights float over it. */
type App = { name: string; title?: string; content: ReactNode };

export const APPS: Record<AppId, App> = {
  editor: { name: "Editor", title: "HotkeyTap.swift — batuta", content: <Editor /> },
  terminal: { name: "Terminal", title: "~/batuta — zsh — 96×32", content: <Terminal /> },
  browser: { name: "Browser", content: <Browser /> },
  notes: { name: "Notes", content: <Notes /> },
  music: { name: "Music", content: <Music /> },
  mail: { name: "Mail", content: <Mail /> },
  chat: { name: "Chat", content: <Chat /> },
  photos: { name: "Photos", content: <Photos /> },
  calendar: { name: "Calendar", content: <Calendar /> },
  maps: { name: "Maps", content: <Maps /> },
  weather: { name: "Weather", content: <Weather /> },
};
