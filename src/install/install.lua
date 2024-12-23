
--[[Seperated version of the GitHub API to make this independent]]--
local function checkHttp()
  if (not http) then
    error("no http library", 3)
  end

  if (not http.checkURL("https://github.com")) then
    error("can't contact github", 3)
  end
end

local github
github = {
  ---Gets a file from a GitHub repo
  ---@param repo string Repository to look in, should be formatted as Author/Repo
  ---@param location string String location of the file
  ---@param branch? string Defaults to 'master'
  ---@return string file data as string
  getFile = function (repo, location, branch)
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
  end,

  ---Gets a file from a GitHub repo, then executes it
  ---@param repo string Repository to look in, should be formatted as Author/Repo
  ---@param location string String location of the file
  ---@param branch? string Defaults to 'master'
  ---@param env? table Environment to pass, defaults to _ENV
  ---@param ... any Arguments to pass to the script
  ---@return any? return Whatever the executed script returns, or nil if it couldn't be executed
  runFile = function (repo, location, branch, env, ...)
    checkHttp()
    branch = branch or "master"
    local file = github.getFile(repo, location)

    local func, err = load(file, location .. "@" .. repo .. " (GitHub)", "t", env)
    if (not func) then error("couldn't load file (" .. err .. ")", 2) end
    pcall(func, ...)
  end,

  ---Gets the contents of a folder from a GitHub repo. \
  ---This API is limited to 1000 files. \
  ---[GitHub REST API Documentation](https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#get-repository-content)
  ---@param repo string Repository to look in, should be formatted as Author/Repo
  ---@param location? string String location of the folder, leave empty for repository root
  ---@param branch? string Defaults to 'master'
  ---@return GitHubFolder data Data of the folder.
  getFolder = function (repo, location, branch)
    location = location or ""
    --TODO: handle symlinks and submodules (https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#get-repository-content#:~:text=If%20the%20content%20is%20a%20symlink,will%20have%20null%20values.)
    checkHttp()
    local query_params = ""
    if (branch) then query_params = "?ref=" .. branch end
    local response, err = http.get("https://api.github.com/repos/" .. repo .. "/contents/" .. location .. query_params, {
      ["Content-Type"] = "application/json",
      ["User-Agent"] = "Reylib",
    })

    if (response) then
      local raw_res = response.readAll()
      response.close()
      if (not raw_res) then error("couldn't read response (", 1) end

      local res, unserialize_err = textutils.unserialiseJSON(raw_res, {
        parse_null = true,
        parse_empty_array = true,
        nbt_style = false,
      })

      res = res --[[@as GitHubFolder]]

      return res and res or error(unserialize_err, 2)
    else
      error("bad argument #1|#2 (" .. err .. ")")
    end
  end,
}

--[[Code]]--

---List of Lua patterns that, if matched on the full path, will not be downloaded
local excludePatterns = {
  "src/install/.*"
}

---@type table<string, table> Full path, args to pass
local installScripts = {
  ["src/install/mkstartup.lua"] = {},
}

-- Parse arguments
local args = { ---@type { [string]: boolean }
  ["silent"] = false,
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

fs.delete("/libs/reylib")
fs.makeDir("/libs/reylib")

---Downloads a file
---@param path string Path
---@return boolean downloaded
local function downloadFile(path)
  local data = github.getFile("Reycko/CCT-Reylib", path)

  local f, err = fs.open("/libs/reylib/" .. (path:sub(1, 4) == "src/" and path:sub(4) or path), "w")
  if (not f) then error("couldn't open file (" .. err .. ")", 2) end

  f.write(data)

  return true
end


local loadFiles

---@param path string
---@return table
loadFiles = function (path)
  local found = {}
  for _, file_data in pairs(github.getFolder("Reycko/CCT-Reylib", path)) do
    if (file_data.type == "dir") then
      for _, file in pairs(loadFiles(file_data.path)) do
        table.insert(found, file)
      end
    elseif (file_data.type == "file") then
      local pattern_matched = false
      for _, pattern in pairs(excludePatterns) do
        if (file_data.path:match(pattern)) then
          pattern_matched = true
          break
        end
      end

      if (not pattern_matched) then
        table.insert(found, file_data.path)
      end
    end
  end

  return found
end

local files = loadFiles("src")
table.insert(files, "VERSION")

local _print = print
---Wraps print to hide when silent.
local function print(...)
  if (not args["silent"]) then _print(...) end
end

print("[Reylib installer started]")

for current_file, file in pairs(files) do
  downloadFile(file)
  print("Downloaded " .. file .. " (" .. current_file .. "/" .. #files .. ")")
end

print("[Running install scripts]")
local scripts_ran = 0
local scripts_to_run = 0
for _, _ in pairs(installScripts) do scripts_to_run = scripts_to_run + 1 end -- HACK: #tbl only works for 'array' tables
-- Run install scripts
for location, args in pairs(installScripts) do
  github.runFile("Reycko/CCT-Reylib", location, "master", nil, table.unpack(args))
  scripts_ran = scripts_ran + 1
  print("Ran install script " .. location .. " (" .. scripts_ran .. "/" .. scripts_to_run .. ")")
end

print("[Reylib installed successfully]")
