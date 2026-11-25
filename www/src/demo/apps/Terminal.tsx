import "./terminal.css";

export const Terminal = () => (
  <div className="app terminal">
    <div><b>~/batuta</b> <i>main</i> $ make run</div>
    <div className="dim">Building for debugging...</div>
    <div className="dim">[42/42] Linking Batuta</div>
    <div className="ok">Build complete! (3.81s)</div>
    <div><b>~/batuta</b> <i>main</i> $ git log --oneline -3</div>
    <div><span className="sha">08c33fe</span> Wrap around inside the stage picker</div>
    <div><span className="sha">1463be8</span> Custom one-window layout for Messy</div>
    <div><span className="sha">d6f0f55</span> Treat small moves as the layout</div>
    <div><b>~/batuta</b> <i>main</i> $ <span className="cursor" /></div>
  </div>
);
