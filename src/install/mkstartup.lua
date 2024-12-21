local Github = require(".libs.reylib.github") ---@module 'src.github'

local data = [[---Reylib auto updater, avoid touching this file.

require(.libs.reylib.github):runFile("Reycko/CCT-Reylib", "src/install/downloader.lua", "master", {}, "silent", "auto", "update")
]]

fs.makeDir("/startup")
local f = io.open("/startup/reylib_auto.lua", "w")
if (f) then
  f:write(data)
  f:flush()
  f:close()
end
