--- Advanced Reylib downloader
--- @return boolean succeded

-- If you wanna paste from this note that the "modules" are just necessary functions to prevent bloat thus are incomplete

local args = { ---@type { [string]: boolean }
  ["auto"] = false,
  ["silent"] = false,
  ["update"] = false,
  ["remove"] = false,
  ["download"] = false,
}

for _, rawArg in pairs({ ... }) do
  rawArg = type(rawArg) == "string" and rawArg or "" ---@type string
  local arg = rawArg
  local setTo = true
  if (arg:sub(1, 3) == "no_" and #arg > 3) then
    setTo = false
    arg = arg:sub(4, #arg)
  end

  args[arg:lower()] = setTo
end

local versions = {
  ---Parses the version
  ---@param version string
  ---@return table versionTable
  parse = function (self, version)
    local versionTable = {}
  
    for v in version:gmatch("[^%.]+") do
      table.insert(versionTable, tonumber(v))
    end
  
    return versionTable
  end,

  ---Compares two versions and returns whether or not the version is the same
  ---@param current number[] Current version, as a table
  ---@param other number[] Other version, as a table
  ---@return boolean
  equal = function (self, current, other)
    if (#current ~= #other) then return false end
    
    for i in #current do
      if (current[i] ~= other[i]) then return false end
    end

    return true
  end,

  ---Compares two versions and returns whether or not the version is lower
  ---@param current number[] Current version, as a table
  ---@param other number[] Other version, as a table
  ---@return boolean
  lessThan = function (self, current, other)
    for i=1,#current do
      if (current[i] < other[i]) then return true end
    end

    return false
  end
}

---Finds Reylib
---@return boolean found, table version
local function findReylib()
  local found = false
  local version = {}

  if (not fs.exists("/libs/reylib")) then return found, version end

  local find = fs.find('/libs/reylib/VERSION')
  if (#find > 0) then
    local f = io.open(find[1], "r")
    if (f ~= nil) then
      found = true
---@diagnostic disable-next-line: undefined-field
      version = versions:parse(f:read("*l"))

      f:close()
    end
  end

  return found, version
end

---Asks question, then returns yes/no.
---@param question string What to ask
---@param choices? table 1 letter choices, first value is yes, second is no
---@param default_no? boolean Default to no instead of yes
local function ask(question, choices, default_no)
  if (args["auto"]) then return not default_no end
  default_no = default_no or false
  choices = choices or {"y", "n"}

  local autocomplete_function = function (partial) require("cc.completion").choice(partial, {"y", "n"}) end
  print(question .. "[" .. (not default_no and choices[1]:upper() or choices[1]:lower()) .. "/" .. (default_no and choices[2]:upper() or choices[2]:lower()) .. "]")
  local input = read(nil, nil, autocomplete_function):lower():sub(1, 1) --- @type string
  if (default_no) then
    return input == choices[1]:lower()
  else
    return input ~= choices[2]:lower()
  end
end

local _print = print
---Wraps print to hide when silent.
local function print(...)
  if (not args["silent"]) then _print(...) end
end

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

---Main function.
---@return boolean succeded
local function main()
  if (not http) then
    print("HTTP has to be enabled in the server config. If you are admin, set http.enabled to true in the server's config.")
    return false
  end

  local rlDownloaded, rlVersion = findReylib()

  if (rlDownloaded) then
    
    if (not args["auto"] and ask("Reylib is already downloaded (v" .. table.concat(rlVersion, ".") .. ").\nDo you want to update [u] or remove [r]?", {"u", "r"}) or (args["update"] and not args["remove"])) then
      -- update
      local shouldUpdate = true
      local rawLatestVersion = paste:get("fneVWbfM")
      if (not rawLatestVersion) then
        print("WARN: Couldn't fetch what the lastest version is")
      else
        shouldUpdate = versions:lessThan(rlVersion, versions:parse(rawLatestVersion))

        print("Downloading " .. rawLatestVersion .. ".")
        paste:run("tc8igxvz")
      end
    else
      -- remove
      if (not fs.exists("/libs/reylib/remove.lua")) then
        print("Couldn't find downloader. Downloading latest one.")
        paste:run("DGJW230q")
      else
---@diagnostic disable-next-line: undefined-field
        os.run({}, "/libs/reylib/remove.lua")
      end
    end

  else
    if (not args["auto"] and ask("Do you want to download Reylib?") or (args["download"])) then
          print("Downloading Reylib.")
          paste:run("tc8igxvz")

          return true
    end
  end

  return true
end

return main()
