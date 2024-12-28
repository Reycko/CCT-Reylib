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

return versionUtils
