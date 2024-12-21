local paste = {
  ---Gets paste from it's ID
  ---@param id string ID of the paste
  ---@return string?
  get = function (self, id)
    local response = http.get("https://pastebin.com/raw/" .. textutils.urlEncode(id) .. "?cb=" .. ("%x"):format(math.random(0, 2 ^ 30)))
  
    if (response) then
      local headers = response.getResponseHeaders() ---@type table
      if (not headers["Content-Type"] or not headers["Content-Type"]:find("^text/plain")) then
        return nil
      end
    end

    local res = response.readAll() ---@type string
    response.close()

    return res
  end,

  ---Runs paste from it's ID
  ---@param id string ID of the paste
  ---@param ... any Arguments to pass
  ---@return any ... Make sure to check if it's not nil
  run = function (self, id, ...)
    local res = self:get(id)

    if (res) then
      local func = load(res, id, "t", _ENV)
      if not func then return nil end

      return func(...)
    end
  end
}

local FILES = {
  ["Yd1xVYfw"] = "paste.lua",
  ["fneVWbfM"] = "VERSION"
}

local RUN = {
  ["7KaQKZmw"] = {}
}

fs.delete("/libs/reylib")
fs.makeDir("/libs/reylib")
for id, file in pairs(FILES) do
  local data = paste:get(id)
  if (not data) then
    print("WARN: Couldn't get file " .. id .. " (supposed to go in " .. FILES .. ")")
  end
    local f = io.open("/libs/reylib/" .. file, "w")
    if (not f) then goto continue end

    f:write(data or "--Couldn't fetch!")
  ::continue::
end

for id, args in pairs(RUN) do
  paste:run(id, args)
end
