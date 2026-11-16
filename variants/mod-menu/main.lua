local goome = require("goome")

local APP_NAME = "My Goome App"

local g, err = goome.open(APP_NAME)
if not g then
  io.stderr:write("couldnt open an overlay: " .. err .. "\n")
  os.exit(1)
end
g:hotkey("alt+m", 1)
local ui = g:ui()
local menu = {x = 80, y = 80, w = 300, open = false}
local fly, god, speed = false, false, 1.0
local running = true
while running do
  for ev in g:events(16) do
    if ev.type == goome.QUIT then running = false end
    if ev.type == goome.HOTKEY then menu.open = not menu.open end
    ui:feed(ev)
  end
  if not running then break end
  local c = ui:begin(0)
  if c then
    if menu.open then
      if ui:window(APP_NAME, menu, goome.WIN_MOVE + goome.WIN_CLOSE) then
        fly = ui:toggle("Fly", fly)
        god = ui:checkbox("God mode", god)
        speed = ui:slider("Speed", speed, 1, 10, "%.1f")
        if ui:button("Respawn") then ui:toast("respawned", 2000) end
      end
      ui:window_end()
    else
      c:round_rect(20, 20, 170, 30, 8, 0xC0202838)
      c:text(32, 26, "alt+m opens the menu", 0xFFFFFFFF)
    end
    ui:finish()
  end
end
g:close()
