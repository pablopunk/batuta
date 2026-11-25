import "./notes.css";

const NOTES = [
  { title: "Stage ideas", date: "9:12", preview: "One stage per project" },
  { title: "Groceries", date: "Yesterday", preview: "Coffee, oranges, rice" },
  { title: "Talk outline", date: "Monday", preview: "Why windows should stay put" },
  { title: "Books", date: "12/11/26", preview: "The Design of Everyday Things" },
];

export const Notes = () => (
  <div className="app notes">
    <aside className="notes-list">
      <div className="notes-header">Notes</div>
      {NOTES.map((note, index) => (
        <div key={note.title} className={index === 0 ? "note-row active" : "note-row"}>
          <b>{note.title}</b>
          <span><em>{note.date}</em> {note.preview}</span>
        </div>
      ))}
    </aside>
    <section className="note-body">
      <div className="note-date">25 November 2026 at 9:12</div>
      <h1>Stage ideas</h1>
      <p>One stage per project, so switching is one key press.</p>
      <ul>
        <li className="done">Editor and terminal side by side</li>
        <li className="done">Music in a stage of its own</li>
        <li>Mail only after lunch</li>
        <li>Try BSP when a stage has 4+ windows</li>
      </ul>
      <p>Messy mode for the browser and notes: they can overlap, it feels like a real desk.</p>
    </section>
  </div>
);
