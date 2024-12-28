local paste = {}

---Gets paste from it's ID
---@param id string ID of the paste
---@param strict? boolean If true, throws an error when the response code is not OK (200) \
---Defaults to false.
---@return string
function paste.get(id, strict)
  strict = strict or false
  local response = http.get("https://pastebin.com/raw/" .. textutils.urlEncode(id) .. "?cb=" .. ("%x"):format(math.random(0, 2 ^ 30)))

  local res ---@type string?
  if (response) then
    local headers = response.getResponseHeaders() ---@type table
    if (not headers["Content-Type"] or not headers["Content-Type"]:find("^text/plain")) then
      error("bad argument #1 (spam filter triggered)", 2)
    end

    if (math.floor(response.getResponseCode() / 200)  ~= 2) then -- non 200 response
      local codeText = table.concat(table.pack(response.getResponseCode()), ", ")
      if (strict) then io.stderr:write(debug.getinfo(2, "S").source .. ": received response code " .. codeText) else error("bad argument #1 (received response code " .. codeText .. ")") end
    end

    res = response.readAll()
    response.close()
  end

  if (not res) then
    error("couldn't read paste (nil result)", 2)
  end
  return res
end

---Gets then runs a paste from pastebin.
---@deprecated Only kept for compatibility. Prefer using `load()`
---@param id string ID of the paste
---@param ... any Arguments to pass to the function
---@return any Nil if the function fails, otherwise whatever the function returned (which includes nil as well)
function paste.run(id, ...)
  local res = paste.get(id)

  if (res) then
    local func = load(res, id, "t", _ENV)
    if not func then return nil end

    return func(...)
  end
end

return paste
