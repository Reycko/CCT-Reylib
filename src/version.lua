local VersionMeta

local isVersion = function (self)
  return type(self) == "table" and getmetatable(self) == VersionMeta
end

---Helper class to parse and use semantic versions
---@class Version
---@field major number
---@field minor number
---@field patch number
Version = {
  ---Parses a version into a tuple of numbers
  ---@param version string
  ---@return number ...
  parse = function (version)
    local found = {} ---@type number[]

    for v in version:gmatch("[^%.]+") do -- gmatch returns an iterator, so we can't directly put it in found
      local number = tonumber(v, 10)
      if (not number or number < 0) then error("Invalid version '" .. version .. "'", 2) end

      table.insert(found, number)
    end

    if (#found ~= 3) then error("invalid semantic version (expected 3 values, got " .. #found .. ")") end
    return table.unpack(found)
  end,

  ---Compares two versions and returns whether or not the current version is the same
  ---@param self Version
  ---@param other Version
  ---@return boolean
  equal = function (self, other)
    if (not isVersion(self)) then error("bad argument #1 (version expected, got " .. type(self) .. ")", 2) end
    if (not isVersion(other)) then error("bad argument #2 (version expected, got " .. type(other) .. ")", 2) end

    return (self.major == other.major and
            self.minor == other.minor and
            self.patch == other.patch)
  end,

  ---Compares two versions and returns whether or not the current version is lower
  ---@param self Version
  ---@param other Version
  ---@return boolean
  lessThan = function (self, other)
    if (not isVersion(self)) then error("bad argument #1 (version expected, got " .. type(self) .. ")", 2) end
    if (not isVersion(other)) then error("bad argument #2 (version expected, got " .. type(other) .. ")", 2) end

    return (self.major < other.major or
            self.minor < other.minor or
            self.patch < other.patch)
  end,

  ---Compares two versions and returns whether or not the current version is greater
  ---@param self Version
  ---@param other Version
  ---@return boolean
  greaterThan = function (self, other)
    if (not isVersion(self)) then error("bad argument #1 (version expected, got " .. type(self) .. ")", 2) end
    if (not isVersion(other)) then error("bad argument #2 (version expected, got " .. type(other) .. ")", 2) end

    if (self.major ~= other.major) then
      return self.major > other.major
    elseif (self.minor ~= other.minor) then
      return self.minor > other.minor
    else
      return self.patch > other.patch
    end
  end,

  ---Makes a new `Version`, which is then parsed
  ---@param self Version
  ---@param version string|{[1]: number, [2]: number, [3]: number} Semantic verion, string separated by dots or as a table
  ---@return Version
  new = function (self, version)
    local major, minor, patch

    if (type(version) == "string") then
      major, minor, patch = self.parse(version)
    elseif (type(version) == "table") then
      if (#version ~= 3) then error("invalid semantic version (expected 3 values, got " .. #version .. ")") end
      major, minor, patch = table.unpack(version)
    else
      error("bad argument #1 (string or table expected, got " .. type(version) .. ")", 2)
    end

    return setmetatable({
      major = major,
      minor = minor,
      patch = patch,
    }, VersionMeta)
  end,
}

---Version metatable
---@type metatable
VersionMeta = {
  __name = "Version",
  ---@param self Version
  __tostring = function (self)
    return string.format("%u.%u.%u", self.major, self.minor, self.patch)
  end,

  __eq = Version.equal,
  __lt = Version.lessThan,
  __index = Version,

  ---@param self Version
  __le = function (self, other)
    return self:lessThan(other) or self:equal(other)
  end,

  ---@param self Version
  __concat = function (self)
    return string.format("%u.%u.%u", self.major, self.minor, self.patch)
  end,
}


return Version
