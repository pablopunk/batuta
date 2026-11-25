import "./calendar.css";

const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const FIRST_WEEKDAY_OFFSET = 6;
const DAYS_IN_MONTH = 30;
const TODAY = 25;

const EVENTS: Record<number, { title: string; color: string }[]> = {
  3: [{ title: "Design review", color: "#0a84ff" }],
  11: [{ title: "Release 0.4", color: "#30d158" }],
  19: [{ title: "Lunch with Nora", color: "#ff9f0a" }],
  25: [{ title: "Standup", color: "#0a84ff" }, { title: "Ship demo", color: "#bf5af2" }],
  27: [{ title: "Dentist", color: "#ff453a" }],
};

const cells = Array.from({ length: 35 }, (_, index) => index - FIRST_WEEKDAY_OFFSET + 1);

export const Calendar = () => (
  <div className="app calendar">
    <div className="calendar-toolbar">
      <b>November</b> 2026
      <span className="segmented-mini"><span>Day</span><span>Week</span><span className="on">Month</span></span>
    </div>
    <div className="calendar-grid">
      {WEEKDAYS.map((day) => <div key={day} className="weekday">{day}</div>)}
      {cells.map((day, index) => {
        const inMonth = day >= 1 && day <= DAYS_IN_MONTH;
        return (
          <div key={index} className={inMonth ? "day" : "day outside"}>
            <span className={day === TODAY ? "date today" : "date"}>{inMonth ? day : ""}</span>
            {inMonth && EVENTS[day]?.map((event) => (
              <span key={event.title} className="event" style={{ borderColor: event.color }}>{event.title}</span>
            ))}
          </div>
        );
      })}
    </div>
  </div>
);
