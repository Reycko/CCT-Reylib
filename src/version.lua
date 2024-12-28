local versionUtils = require(".libs.reylib.versionUtils") ---@module "src.versionUtils"

---Helper class to parse and use semantic versions
---@class Version
---@field major number
---@field minor number
---@field patch number
local Version = {}
Version.__index = Version

---Makes a new `Version`, which is then parsed
---@param version string|{[1]: number, [2]: number, [3]: number} Semantic verion, string separated by dots or as a table
---@return Version
function Version.new(version)
  local self = setmetatable({}, Version)

  if (type(version) == "string") then
    self.major, self.minor, self.patch = table.unpack(versionUtils.parse(version))
  elseif (type(version) == "table") then
    if (#version ~= 3) then error("invalid semantic version (expected 3 values, got " .. #version .. ")") end
    self.major, self.minor, self.patch = table.unpack(version)
  else
    error("bad argument #1 (string or table expected, got " .. type(version) .. ")", 2)
  end

  return self
end

---Compares two versions and returns whether or not the current version is the same
---@param self Version
---@param other Version
---@return boolean
function Version:equal(other)
  return (self.major == other.major and
          self.minor == other.minor and
          self.patch == other.patch)
end

---Compares two versions and returns whether or not the current version is lower
---@param self Version
---@param other Version
---@return boolean
function Version:lessThan(other)
  if (self.major ~= other.major) then
    return self.major < other.major
  elseif (self.minor ~= other.minor) then
    return self.minor < other.minor
  else
    return self.patch < other.patch
  end
end

---Compares two versions and returns whether or not the current version is greater
---@param self Version
---@param other Version
---@return boolean
function Version:greaterThan(other)
  if (self.major ~= other.major) then
    return self.major > other.major
  elseif (self.minor ~= other.minor) then
    return self.minor > other.minor
  else
    return self.patch > other.patch
  end
end

---Parses a version into a tuple of numbers
---@deprecated This function is only kept for compatibility. Use the function with the same name from versionUtils.
---@param version string
---@return number ...
function Version.parse(version)
  local found = {} ---@type number[]

  for v in version:gmatch("[^%.]+") do
    local number = tonumber(v, 10)
    if (not number or number < 0) then error("Invalid version '" .. version "'", 2) end -- Errors should NOT be formatted like this. Kept for compatibility.

    table.insert(found, number)
  end

  if (#found ~= 3) then error("invalid semantic version (expected 3 values, got " .. #found .. ")") end
  return table.unpack(found)
end

Version.__name = "version"

Version.__eq = Version.equal
Version.__lt = Version.lessThan

function Version:__tostring()
  return string.format("%u.%u.%u", self.major, self.minor, self.patch)
end

function Version:__le(other)
  return self:lessThan(other) or self:equal(other)
end

return Version
