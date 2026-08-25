local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

addonTable.Enums = {}
addonTable.MapUtils = {}
addonTable.CombatLockdownUtils = {}

local MapUtils = addonTable.MapUtils
local Enums = addonTable.Enums
local CombatLockdownUtils = addonTable.CombatLockdownUtils

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

Enums.TransmogMenagerieSlot = {
  Companion = 0,
  Mount = 1,
  FlyingMount = 2,
  GroundMount = 3
}

Enums.TransmogMenagerieSlotType = {
  Companion = 0,
  Mount = 1
}

--------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------

function CombatLockdownUtils.Dispatch(action, msg)
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

--------------------------------------------------------------------------------
--- Map Utilities
--------------------------------------------------------------------------------

function MapUtils.GetInstanceZoneType()
  if IsResting() then
    return "RESTING"
  end
  local _, instanceType = IsInInstance()
  return Enums.INSTANCE_TYPES[instanceType] or "GLOBAL"
end

function MapUtils.GetContinentIDForMap(mapID)
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

function MapUtils.GetPlayerMapInfoForScope(scope)
  if scope == Enums.SCOPES.continent then
    local _, continentId = MapUtils:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    return C_Map.GetMapInfo(continentId)
  end

  if scope == Enums.SCOPES.zone then
    return C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player"))
  end
  return nil
end
