import "./mail.css";

const MAILBOXES: [name: string, count?: number][] = [["Inbox", 3], ["VIP"], ["Flagged"], ["Drafts", 1], ["Sent"], ["Archive"]];

const MESSAGES = [
  { from: "Lucía Ferreira", time: "9:04", subject: "Design review moved to Thursday", preview: "Hi! Can we push the review to Thursday? The new tiling…" },
  { from: "Build Bot", time: "8:41", subject: "main passed: 42 checks", preview: "All checks passed for 08c33fe Wrap around inside the…" },
  { from: "Tomás Ruiz", time: "Yesterday", subject: "Stage Manager tips", preview: "Saw your post about keeping a stage per project…" },
  { from: "Nora Lind", time: "Yesterday", subject: "Lunch on Friday?", preview: "There's a new ramen place near the office…" },
  { from: "Fieldnotes", time: "Monday", subject: "This week: calmer desktops", preview: "Five small habits that keep your screen tidy…" },
];

export const Mail = () => (
  <div className="app mail">
    <aside className="mailboxes">
      <div className="mail-section">Favourites</div>
      {MAILBOXES.map(([name, count]) => (
        <div key={name} className={name === "Inbox" ? "mailbox active" : "mailbox"}>
          <span>{name}</span>
          {count && <em>{count}</em>}
        </div>
      ))}
    </aside>
    <div className="message-list">
      <div className="list-header"><b>Inbox</b><span>5 messages, 3 unread</span></div>
      {MESSAGES.map((message, index) => (
        <div key={message.subject} className={index === 0 ? "message active" : index < 3 ? "message unread" : "message"}>
          <div className="row"><b>{message.from}</b><time>{message.time}</time></div>
          <div className="subject">{message.subject}</div>
          <div className="preview">{message.preview}</div>
        </div>
      ))}
    </div>
    <section className="reader">
      <div className="reader-head">
        <span className="avatar">LF</span>
        <div><b>Lucía Ferreira</b><span>To: me · 9:04</span></div>
      </div>
      <h2>Design review moved to Thursday</h2>
      <p>Hi!</p>
      <p>Can we push the review to Thursday? The new tiling modes need one more pass, and I want to try Messy on the big screen first.</p>
      <p>I'll bring the custom layouts we drew last week.</p>
      <p>Thanks,<br />Lucía</p>
    </section>
  </div>
);
