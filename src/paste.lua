local paste
paste = {
  ---Gets paste from it's ID
  ---@param id string ID of the paste
  ---@return string?
  get = function (id)
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
  run = function (id, ...)
    local res = paste.get(id)

    if (res) then
      local func = load(res, id, "t", _ENV)
      if not func then return nil end

      return func(...)
    end
  end
}

return paste
