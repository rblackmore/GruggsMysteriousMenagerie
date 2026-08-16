local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

local Utilities = addOn.Utilities
local Enums = Utilities.Enums

--------------------------------------------------------------------------------
--- Enums
--------------------------------------------------------------------------------

Enums.INSTANCE_TYPES = {

  ["pvp"] = "BATTLEGROUND",
  ["arena"] = "ARENA",
  ["party"] = "DUNGEON",
  ["raid"] = "RAID",
  ["scenario"] = "SCENARIO",
  ["neighborhood"] = "NEIGHBORHOOD",
  ["none"] = "GLOBAL",
}

Enums.SCOPES = {
  world = "world",
  w = "world",
  continent = "continent",
  c = "continent",
  zone = "zone",
  z = "zone",
  outfit = "outfit",
  o = "outfit"
}

--------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------

function Utilities:GetInstanceZoneType()
  if IsResting() then
    return "RESTING"
  end
  local _, instanceType = IsInInstance()
  return Enums.INSTANCE_TYPES[instanceType] or "GLOBAL"
end

function Utilities:DispatchIfInCombatLockdown(action, msg)
  if InCombatLockdown() then
    if msg then
      addOn:Print(msg);
    end
    addOn:RegisterEvent("PLAYER_REGEN_ENABLED", function(...)
      addOn:UnregisterEvent("PLAYER_REGEN_ENABLED")
      action()
    end)
  else
    action()
  end
end

function Utilities:GetContinentIDForMap(mapID)
  local info = mapID and C_Map.GetMapInfo(mapID)
  while info do
    if info.mapType == Enum.UIMapType.Continent then
      return true, info.mapID
    end
    if not info.parentMapID then break end
    info = C_Map.GetMapInfo(info.parentMapID)
  end
  return false, nil
end
