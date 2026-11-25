import type { ReactNode } from "react";
import "./app.css";
import type { AppId } from "../state";
import { Browser } from "./Browser";
import { Chat } from "./Chat";
import { Editor } from "./Editor";
import { Mail } from "./Mail";
import { Music } from "./Music";
import { Notes } from "./Notes";
import { Photos } from "./Photos";
import { Terminal } from "./Terminal";

/** `title` draws a classic title bar; without it the app draws its own top and the traffic lights float over it. */
type App = { name: string; title?: string; dark: boolean; content: ReactNode };

export const APPS: Record<AppId, App> = {
  editor: { name: "Editor", title: "HotkeyTap.swift — batuta", dark: true, content: <Editor /> },
  terminal: { name: "Terminal", title: "~/batuta — zsh — 96×32", dark: true, content: <Terminal /> },
  browser: { name: "Browser", dark: false, content: <Browser /> },
  notes: { name: "Notes", dark: false, content: <Notes /> },
  music: { name: "Music", dark: true, content: <Music /> },
  mail: { name: "Mail", dark: false, content: <Mail /> },
  chat: { name: "Chat", dark: false, content: <Chat /> },
  photos: { name: "Photos", dark: false, content: <Photos /> },
};
