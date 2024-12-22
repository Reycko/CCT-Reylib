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

return github
