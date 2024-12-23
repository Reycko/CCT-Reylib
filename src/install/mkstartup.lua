fs.makeDir("/startup")
local f = io.open("/startup/reylib_auto.lua", "w")
if (f) then
  f:write([[
---Reylib auto updater, avoid touching this file.

require(".libs.reylib.github").runFile("Reycko/CCT-Reylib", "src/install/downloader.lua", "master", nil, "silent", "auto", "update")
]])
  f:flush()
  f:close()
end
