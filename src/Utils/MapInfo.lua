local _, addonTable = ...

local GMM_MapInfo = {}
addonTable["GMM_MapInfo"] = GMM_MapInfo

local instanceTypes = {

  ["pvp"] = "BATTLEGROUND",
  ["arena"] = "ARENA",
  ["party"] = "DUNGEON",
  ["raid"] = "RAID",
  ["scenario"] = "SCENARIO",
  ["none"] = "GLOBAL",
}

local function convertInstanceTypeToZoneType(instanceType)
  local zoneType = instanceTypes[instanceType]
  return zoneType or ""
end

function GMM_MapInfo:GetCurrentZoneType()
  if IsResting() then
    return "RESTING"
  end
  local _, instanceType = IsInInstance()
  return convertInstanceTypeToZoneType(instanceType)
end

function GMM_MapInfo:ConvertDbNumberToMapType(number)
  local mapTypes = {
    [0] = "COSMIC",
    [1] = "WORLD",
    [2] = "CONTINENT",
    [3] = "ZONE",
    [4] = "DUNGEON",
    [5] = "MICRO",
    [6] = "ORPHAN"
  }
  local mapType = mapTypes[number]
  return mapType or ""
end
