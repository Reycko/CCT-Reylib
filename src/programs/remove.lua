if (debug.getinfo(2) and debug.getinfo(2, "S").source:match("@/rom/modules/main/cc/require%.lua")) then -- file has been require'd
  error([[

!!!!!!!!!!!!!!! 
!!!SAFEGUARD!!!
!!!!!!!!!!!!!!!

This script has attempted to `require` Reylib's remove.lua.
If you are the developer, fix this ASAP!]]
  , 3)
end

fs.delete("/libs/reylib")
if (#fs.list("/libs") == 0) then fs.delete("/libs") end -- I doubt many scripts make a /libs folder.
fs.delete("/startup/reylib_auto.lua")
print("Removed Reylib.")
