local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local MapInfo = {}

local instanceTypes = {

  ["pvp"] = "BATTLEGROUND",
  ["arena"] = "ARENA",
  ["party"] = "DUNGEON",
  ["raid"] = "RAID",
  ["scenario"] = "SCENARIO",
  ["none"] = "GLOBAL",
}

function MapInfo:GetCurrentZoneType()
  if IsResting() then
    return "RESTING"
  end
  local _, instanceType = IsInInstance()
  return instanceTypes[instanceType] or ""
end

function MapInfo:ConvertDbNumberToMapType(number)
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

addOn.MapInfo = MapInfo
