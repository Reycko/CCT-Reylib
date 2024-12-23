---@diagnostic disable: deprecated
--- Advanced Reylib downloader
--- @return boolean succeded

-- If you wanna paste from this, note that the "modules" are just necessary functions to prevent bloat thus are incomplete

--[[===Library definitions===]]--
-- These are defined here because this downloader should have no dependencies.

--[[
We'll use versionfns instead of the `Version` class as it's more portable and this script is meant to stay short.
]]

---Multiple helper functions for versions
local versionfns = {
  ---Parses the version \
  ---Unlike the `Version` class, this returns it as a table instead of a tuple
  ---to fit the other functions
  ---@deprecated Use version class instead
  ---@param version string
  ---@return table versionTable
  parse = function (version)
    local found = {} ---@type number[]

    for v in version:gmatch("[^%.]+") do -- gmatch returns an iterator, so we can't directly put it in found
      local number = tonumber(v, 10)
      if (not number or number < 0) then error("Invalid version '" .. version .. "'", 2) end

      table.insert(found, number)
    end

    if (#found ~= 3) then error("invalid semantic version (expected 3 values, got " .. #found .. ")") end
    return found
  end,

  ---Compares two versions and returns whether or not the current version is the same
  ---@deprecated Use version class instead
  ---@param current number[] Current version, as a table
  ---@param other number[] Other version, as a table
  ---@return boolean
  equal = function (current, other)
    if (#other ~= 3) then error("bad argument #2 (expected 3 values, got " .. #other .. ")", 2) end
    if (#current ~= 3) then error("bad argument #1 (expected 3 values, got " .. #other .. ")", 2) end

    for i in #current do
      if (current[i] ~= other[i]) then return false end
    end

    return true
  end,

  ---Compares two versions and returns whether or not the current version is lower
  ---@deprecated Use version class instead
  ---@param current number[] Current version, as a table
  ---@param other number[] Other version, as a table
  ---@return boolean
  lessThan = function (current, other)
    if (#other ~= 3) then error("bad argument #2 (expected 3 values, got " .. #other .. ")", 2) end
    if (#current ~= 3) then error("bad argument #1 (expected 3 values, got " .. #other .. ")", 2) end

    for i=1,#current do
      if (current[i] < other[i]) then
        return true
      elseif (current[i] > other[i]) then
        return false
      end
    end

    return false
  end,

  ---Compares two versions are returns whether or not the current version is greater
  ---@deprecated Use version class instead
  ---@param current any
  ---@param other any
  ---@return boolean
  greaterThan = function (current, other)
    if (#other ~= 3) then error("bad argument #2 (expected 3 values, got " .. #other .. ")", 2) end
    if (#current ~= 3) then error("bad argument #1 (expected 3 values, got " .. #other .. ")", 2) end

    for i=1,#current do
      if (current[i] > other[i]) then
        return true
      elseif (current[i] < other[i]) then
        return false
      end
    end

    return false
  end,
}

local github
github = {
  ---Gets a file from a GitHub repo
  ---@param repo string Repository to look in, should be formatted as Author/Repo
  ---@param location string String location of the file
  ---@param branch? string Defaults to 'master'
  ---@return string File data as string
  getFile = function (repo, location, branch)
    branch = branch or "master"
    local response = http.get("https://raw.githubusercontent.com/" .. textutils.urlEncode(repo) .. "/refs/heads/" .. textutils.urlEncode(branch) .. "/" .. location .. "?cb=" .. ("%x"):format(math.random(0, 2^30)))
    if (response) then
      local res = response.readAll()
      response.close()
      return res
    end

    return ""
  end,

  ---Gets a file from a GitHub repo, then executes it
  ---@param repo string Repository to look in, should be formatted as Author/Repo
  ---@param location string String location of the file
  ---@param branch? string Defaults to 'master'
  ---@param env? table Environment to pass, defaults to _ENV
  ---@param ... any Arguments to pass to the script
  ---@return any? return Whatever the executed script returns, or nil if it couldn't be executed
  runFile = function (repo, location, branch, env, ...)
    branch = branch or "master"
    env = env or _ENV
    local file = github.getFile(repo, location)

    load(file, location .. "@" .. repo .. " (GitHub)", "t", env)(...)
  end
}

--[[===Code===]]--

-- Parse arguments
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
    arg = arg:sub(4)
  end

  args[arg:lower()] = setTo
end

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
      version = versionfns.parse(f:read())

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

  local autocomplete_function = function (partial) require("cc.completion").choice(partial, choices) end
  print(question .. " [" .. (not default_no and choices[1]:upper() or choices[1]:lower()) .. "/" .. (default_no and choices[2]:upper() or choices[2]:lower()) .. "]")
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

---Main function.
---@return boolean succeded
local function main()
  if (not http) then
    print("HTTP has to be enabled in the server config.\nIf you are admin, set http.enabled to true in the server's config.")
    return false
  end

  if (not http.checkURL("https://github.com")) then
    print("Couldn't contact GitHub.\nIf you are admin, make sure github.com is allowed in the server's config.\nIn singleplayer, make sure you are connected to the internet.")
    return false
  end

  local rlDownloaded, rlVersion = findReylib()

  if (rlDownloaded) then
    if (not args["auto"] and ask("Reylib is already downloaded (v" .. table.concat(rlVersion, ".") .. ").\nDo you want to update [u] or remove [r]?", {"u", "r"}) or (args["update"] and not args["remove"])) then
      -- update
      local shouldUpdate = true
      local rawLatestVersion = github.getFile("Reycko/CCT-Reylib", "VERSION")
      if (not rawLatestVersion) then
        print("WARN: Couldn't fetch what the lastest version is")
      else
        shouldUpdate = versionfns.lessThan(rlVersion, versionfns.parse(rawLatestVersion))
        if (not args["auto"] and not shouldUpdate) then
          shouldUpdate = ask("You already have the latest version of Reylib.\nAre you sure you want to download it anyway?", nil, true)
        end

        print("Downloading " .. rawLatestVersion .. ".")
        github.runFile("Reycko/CCT-Reylib", "src/install/install.lua", "master", _G)
      end
    else
      -- remove
      if (not fs.exists("/libs/reylib/programs/remove.lua")) then
        print("Couldn't find remover. Downloading latest one.")
        github.runFile("Reycko/CCT-Reylib", "src/install/remove.lua", "master", _G)
      else
---@diagnostic disable-next-line: undefined-field
        os.run({}, "/libs/reylib/remove.lua")
      end
    end

  else
    if (not args["auto"] and ask("Do you want to download Reylib?") or (args["download"])) then
          print("Downloading Reylib.")
          github.runFile("Reycko/CCT-Reylib", "src/install/install.lua", "master", _G)

          return true
    end
  end

  return true
end

return main()
