local goome = require("goome")

local APP_NAME = "My Goome App"

local s = {clicks = 0, volume = 0.5, overlay = false, shown = false}

local function open_mode(overlay)
  if not overlay then return goome.open_app(APP_NAME, 640, 420) end
  local g, err = goome.open(APP_NAME)
  if not g then return nil, err end
  local m = g:monitors()[1]
  return g, {x = m and m.area.x + m.area.w - 340 or 40, y = 60, w = 300}
end

local function contents(ui)
  s.overlay = ui:toggle("Overlay mode", s.overlay)
  ui:separator()
  ui:push_color(goome.S_TEXT, ui:anim_color("hello", s.shown and 0xFFF2F4F8 or 0x00F2F4F8, 600, goome.EASE_OUT))
  s.shown = true
  ui:heading("Hello from " .. APP_NAME)
  ui:pop(1)
  if ui:button("Click me") then s.clicks = s.clicks + 1 end
  ui:label(string.format("clicked %d times", s.clicks))
  s.volume = ui:slider("Volume", s.volume, 0, 1, "%.2f")
end

local g, win = open_mode(false)
if not g then
  io.stderr:write("couldnt open a window: " .. tostring(win) .. "\n")
  os.exit(1)
end
local ui = g:ui()
local mode = false
local running = true
while running do
  for ev in g:events(16) do
    if ev.type == goome.QUIT or ev.type == goome.CLOSE then running = false end
    ui:feed(ev)
  end
  if not running then break end
  if s.overlay ~= mode then
    g:close()
    g, win = open_mode(s.overlay)
    if not g then
      io.stderr:write("no overlay here, staying in window mode\n")
      s.overlay = false
      g, win = assert(open_mode(false))
    end
    mode = s.overlay
    ui = g:ui()
    print(mode and "overlay mode" or "window mode")
    io.stdout:flush()
  elseif ui:begin(0) then
    if mode then
      if ui:window(APP_NAME, win, goome.WIN_MOVE + goome.WIN_COLLAPSE) then contents(ui) end
      ui:window_end()
    else
      ui:app(APP_NAME)
      contents(ui)
      ui:app_end()
    end
    ui:finish()
  end
end
g:close()
