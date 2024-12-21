local paste = require(".libs.reylib.paste") ---@module 'src.paste'

local data = "---Reylib auto updater---\n"

data = data .. "local paste = " .. paste:get("Yd1xVYfw"):sub(8) .. "\n"

data = data .. [[
paste:run("GSqi5v2z", "silent", "auto", "update")
]]

fs.makeDir("/startup")
local f = io.open("/startup/reylib_auto.lua", "w")
if (f) then
  f:write(data)
  f:flush()
  f:close()
end
