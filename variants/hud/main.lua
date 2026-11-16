local goome = require("goome")

local APP_NAME = "My Goome App"

local g, err = goome.open(APP_NAME)
if not g then
  io.stderr:write("couldnt open an overlay: " .. err .. "\n")
  os.exit(1)
end
g:hotkey("alt+h", 1)
local start = goome.now_ms()
local last = start
local fps, hidden, running = 0, false, true
local pace = goome.pacer(30)
while running do
  for ev in g:events(pace:wait()) do
    if ev.type == goome.QUIT then running = false end
    if ev.type == goome.HOTKEY then hidden = not hidden end
  end
  if not running then break end
  local now = goome.now_ms()
  if now > last then fps = fps * 0.9 + 100 / (now - last) end
  last = now
  local c = g:begin(0)
  if c then
    if not hidden then
      c:round_rect(20, 20, 160, 92, 10, 0xB0141820)
      c:text(34, 30, os.date("%H:%M:%S"), 0xFFFFFFFF, true)
      c:text(34, 62, string.format("up %ds", math.floor((now - start) / 1000)), 0xFFC0C8D0)
      c:text(34, 84, string.format("%.0f fps", fps), 0xFF6FDC5F)
    end
    g:finish(c)
  end
end
g:close()
