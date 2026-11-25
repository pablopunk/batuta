import "./weather.css";

const HOURS = [
  ["Now", "☀", 18], ["10", "☀", 19], ["11", "⛅", 20], ["12", "⛅", 21], ["13", "☁", 20], ["14", "🌧", 17],
] as const;

const DAYS = [
  ["Today", "☀", 12, 21], ["Thu", "⛅", 11, 19], ["Fri", "🌧", 9, 15], ["Sat", "☀", 10, 18],
] as const;

export const Weather = () => (
  <div className="app weather">
    <div className="weather-now">
      <span>Lisbon</span>
      <b>18°</b>
      <span>Sunny · H:21° L:12°</span>
    </div>
    <div className="weather-card hours">
      {HOURS.map(([hour, symbol, temperature]) => (
        <div key={hour}><span>{hour}</span><i>{symbol}</i><b>{temperature}°</b></div>
      ))}
    </div>
    <div className="weather-card days">
      {DAYS.map(([day, symbol, low, high]) => (
        <div key={day}><span>{day}</span><i>{symbol}</i><em>{low}°</em><b className="range" /><em>{high}°</em></div>
      ))}
    </div>
  </div>
);
