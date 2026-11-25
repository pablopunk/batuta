import "./chat.css";

const CONVERSATIONS = [
  { name: "Ana", last: "this one is messy on purpose", color: "#ff9f0a", time: "9:20" },
  { name: "Design team", last: "Lucía: Thursday works", color: "#30d158", time: "9:05" },
  { name: "Marco", last: "📷 Photo", color: "#64d2ff", time: "Yesterday" },
  { name: "Dad", last: "Call me when you can", color: "#bf5af2", time: "Monday" },
];

const MESSAGES: [from: "me" | "them", text: string][] = [
  ["them", "ship it?"],
  ["me", "one more tiling mode"],
  ["them", "you said that yesterday 😅"],
  ["me", "this one is messy on purpose"],
  ["them", "ok that's actually nice"],
];

export const Chat = () => (
  <div className="app chat">
    <aside className="conversations">
      <div className="chat-search">⌕ Search</div>
      {CONVERSATIONS.map((conversation, index) => (
        <div key={conversation.name} className={index === 0 ? "conversation active" : "conversation"}>
          <span className="avatar" style={{ background: conversation.color }}>{conversation.name[0]}</span>
          <div>
            <div className="row"><b>{conversation.name}</b><time>{conversation.time}</time></div>
            <span>{conversation.last}</span>
          </div>
        </div>
      ))}
    </aside>
    <section className="thread">
      <div className="thread-head"><span className="avatar" style={{ background: "#ff9f0a" }}>A</span><b>Ana</b></div>
      <div className="bubbles">
        <div className="stamp">Today 9:18</div>
        {MESSAGES.map(([from, text]) => (
          <div key={text} className={`bubble ${from}`}>{text}</div>
        ))}
      </div>
      <div className="composer">Message</div>
    </section>
  </div>
);
