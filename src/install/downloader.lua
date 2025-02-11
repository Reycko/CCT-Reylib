---@diagnostic disable: deprecated
--- Advanced Reylib downloader
--- @return boolean succeded

-- If you wanna paste from this, note that the "modules" are just necessary functions to prevent bloat thus are incomplete

--[[===Library definitions===]]--
-- These are defined here because this downloader should have no dependencies.

--[[
We'll use versionUtils instead of the `Version` class as it's more portable and this script is meant to stay short.
]]

---Multiple helper functions for versions
local versionUtils = {}

---Parses the version \
---Unlike the `Version` class, this returns it as a table instead of a tuple
---to fit the other functions
---@param version string
---@return table versionTable
function versionUtils.parse(version)
  local found = {} ---@type number[]

  for v in version:gmatch("[^%.]+") do -- gmatch returns an iterator, so we can't directly put it in found
    local number = tonumber(v, 10)
    if (not number or number < 0) then error("invalid semantic version (" .. version .. ")", 2) end

    table.insert(found, number)
  end

  if (#found ~= 3) then error("bad argument #1 (expected 3 values, got " .. #found .. ")") end
  return found
end

---Compares two versions and returns whether or not the current version is the same
---@deprecated Use version class instead
---@param current number[] Current version, as a table
---@param other number[] Other version, as a table
---@return boolean
function versionUtils.equal(current, other)
  if (#other ~= 3) then error("bad argument #2 (expected 3 values, got " .. #other .. ")", 2) end
  if (#current ~= 3) then error("bad argument #1 (expected 3 values, got " .. #other .. ")", 2) end

  for i in #current do
    if (current[i] ~= other[i]) then return false end
  end

  return true
end

---Compares two versions and returns whether or not the current version is lower
---@deprecated Use version class instead
---@param current number[] Current version, as a table
---@param other number[] Other version, as a table
---@return boolean
function versionUtils.lessThan(current, other)
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
end

---Compares two versions are returns whether or not the current version is greater
---@deprecated Use version class instead
---@param current any
---@param other any
---@return boolean
function versionUtils.greaterThan(current, other)
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
end

local function checkHttp()
  if (not http) then
    error("no http library", 3)
  end

  if (not http.checkURL("https://github.com")) then
    error("can't contact github", 3)
  end
end

local github = {}

---Gets a file from a GitHub repo
---@param repo string Repository to look in, should be formatted as Author/Repo
---@param location string String location of the file
---@param branch? string Defaults to 'master'
---@return string file data as string
function github.getFile(repo, location, branch)
  checkHttp()
  branch = branch or "master"
  local response, err = http.get("https://raw.githubusercontent.com/" .. textutils.urlEncode(repo) .. "/refs/heads/" .. textutils.urlEncode(branch) .. "/" .. location .. "?cb=" .. ("%x"):format(math.random(0, 2^30)))
  if (response) then
    local res = response.readAll()
    response.close()
    if (not res) then error("couldn't read file (empty response, possibly nonexistent file)") end
    return res
  end

  error("couldn't read file (" .. tostring(err) .. ")", 2)
end

---Gets a file from a GitHub repo, then executes it
---@param repo string Repository to look in, should be formatted as Author/Repo
---@param location string String location of the file
---@param branch? string Defaults to 'master'
---@param env? table Environment to pass, defaults to _ENV
---@param ... any Arguments to pass to the script
---@return any? return Whatever the executed script returns, or nil if it couldn't be executed
function github.runFile(repo, location, branch, env, ...)
  checkHttp()
  branch = branch or "master"
  local file = github.getFile(repo, location)

  local func, err = load(file, location .. "@" .. repo .. " (GitHub)", "t", env)
  if (not func) then error("couldn't load file (" .. err .. ")", 2) end
  pcall(func, ...)
end

local cliUtils = {}

---Asks a question, then returns yes/no.
---@param question string What to ask
---@param choices? table 1 letter choices, first value is yes, second is no
---@param default_no? boolean Default to no instead of yes
function cliUtils.ask(question, choices, default_no)
  default_no = default_no or false
  choices = choices or {"y", "n"}
  for _, choice in pairs(choices) do
    choice = choice:lower():sub(1, 1)
  end

  local autocomplete_function = function (partial) require("cc.completion").choice(partial, choices) end
  local yes_text = (default_no and choices[1] or choices[1]:upper())
  local no_text = (default_no and choices[2]:upper() or choices[2])

  print(question .. " [" .. yes_text .. "/" .. no_text .. "]")
  local input = read(nil, nil, autocomplete_function):lower():sub(1, 1)
  if (default_no) then
    return input == choices[1]
  else
    return input ~= choices[2]
  end
end

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
      version = versionUtils.parse(f:read())

      f:close()
    end
  end

  return found, version
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

  local rawLatestVersion = github.getFile("Reycko/CCT-Reylib", "VERSION")
  local rlDownloaded, rlVersion = findReylib()

  if (rlDownloaded) then
    if (not args["auto"] and cliUtils.ask("Reylib is already downloaded (v" .. table.concat(rlVersion, ".") .. ").\nThe latest version is v" .. rawLatestVersion .. "\nDo you want to update [u] or remove [r]?", {"u", "r"}) or (args["update"] and not args["remove"])) then
      -- update
      local shouldUpdate = versionUtils.lessThan(rlVersion, versionUtils.parse(rawLatestVersion))
      if (not args["auto"] and not shouldUpdate) then
        shouldUpdate = cliUtils.ask("You already have the latest version of Reylib.\nAre you sure you want to download it anyway?", nil, true)
      end

      if (shouldUpdate) then
        print("Downloading " .. rawLatestVersion .. ".")
        github.runFile("Reycko/CCT-Reylib", "src/install/install.lua", rawLatestVersion, _G, "version", rawLatestVersion)
      end
    else
      -- remove
      if (not fs.exists("/libs/reylib/programs/remove.lua")) then
        print("Couldn't find remover. Downloading it from GitHub.")
        github.runFile("Reycko/CCT-Reylib", "src/programs/remove.lua", table.concat(rlVersion, "."), _G)
      else
---@diagnostic disable-next-line: undefined-field
        os.run({}, "/libs/reylib/programs/remove.lua")
      end
    end

  else
    if (not args["auto"] and cliUtils.ask("Do you want to download Reylib?") or (args["download"])) then
          print("Downloading Reylib.")
          github.runFile("Reycko/CCT-Reylib", "src/install/install.lua", rawLatestVersion, _G)

          return true
    end
  end

  return true
end

return main()
