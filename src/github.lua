---@alias GitHubFolder_FileType "dir"|"file"|"submodule"
---@alias GitHubFolder { name: string, path: string, sha: string, size: number, url: string, html_url: string, git_url: string, download_url?: string, type: GitHubFolder_FileType, _links: { self: string, git: string, html: string } } The API response to GitHub's repos/{repo}/contents API

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

      return res and res or error(unserialize_err, 2)
    else
      error("bad argument #1|#2 (" .. err .. ")")
    end
  end,
}

return github
