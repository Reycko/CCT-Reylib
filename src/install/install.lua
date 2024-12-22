---@class Github
local Github = {
  ---Gets a file from a GitHub repo
  ---@param self Github
  ---@param repo string Repository to look in, should be formatted as Author/Repo
  ---@param location string String location of the file
  ---@param branch? string Defaults to 'master'
  ---@return string File data as string
  getFile = function (self, repo, location, branch)
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
  ---@param self Github
  ---@param repo string Repository to look in, should be formatted as Author/Repo
  ---@param location string String location of the file
  ---@param branch? string Defaults to 'master'
  ---@param env? table Environment to pass, defaults to _ENV
  ---@param ... any Arguments to pass to the script
  ---@return any? return Whatever the executed script returns, or nil if it couldn't be executed
  runFile = function (self, repo, location, branch, env, ...)
    branch = branch or "master"
    env = env or _ENV
    local file = self:getFile(repo, location)

    load(file, location .. "@" .. repo .. " (GitHub)", "t", env)(...)
  end
}

local FILES = {
  ["src/paste.lua"] = "paste.lua",
  ["src/github.lua"] = "github.lua",
  ["VERSION"] = "VERSION",
}

local RUN = {
  ["src/install/mkstartup.lua"] = {},
}

fs.delete("/libs/reylib")
fs.makeDir("/libs/reylib")
for location, file in pairs(FILES) do
  local data = Github:getFile("Reycko/CCT-Reylib", location)
  if (not data) then
    print("WARN: Couldn't get file " .. location .. " (supposed to go in " .. file .. ")")
  end

  local f = io.open("/libs/reylib/" .. file, "w")
  if (not f) then goto continue end

  f:write(data or "--Couldn't fetch!")
  ::continue::
end

for location, args in pairs(RUN) do
  Github:runFile("Reycko/CCT-Reylib", location, "master", _ENV, table.unpack(args))
end
