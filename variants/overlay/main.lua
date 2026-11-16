local goome = require("goome")

local APP_NAME = "My Goome App"

local g, err = goome.open(APP_NAME)
if not g then
  io.stderr:write("couldnt open an overlay: " .. err .. "\n")
  os.exit(1)
end
g:hotkey("alt+h", 1)
local ui = g:ui()
local win = {x = 60, y = 60, w = 280, open = true}
local clicks, hidden = 0, false
while win.open do
  for ev in g:events(16) do
    if ev.type == goome.QUIT then win.open = false end
    if ev.type == goome.HOTKEY then hidden = not hidden end
    ui:feed(ev)
  end
  if win.open and ui:begin(0) then
    if not hidden then
      if ui:window(APP_NAME, win, goome.WIN_MOVE + goome.WIN_CLOSE) then
        ui:label("im on top of everything")
        if ui:button("Click me") then clicks = clicks + 1 end
        ui:label(string.format("clicked %d times", clicks))
        ui:label("alt+h hides me")
      end
      ui:window_end()
    end
    ui:finish()
  end
end
g:close()
