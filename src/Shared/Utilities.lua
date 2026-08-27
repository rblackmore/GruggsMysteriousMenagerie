local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)

addonTable.Enums = {}
addonTable.MapUtils = {}
addonTable.CombatLockdownUtils = {}
addonTable.Models = {}

local MapUtils = addonTable.MapUtils
local Enums = addonTable.Enums
local CombatLockdownUtils = addonTable.CombatLockdownUtils
local Models = addonTable.Models

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

--------------------------------------------------------------------------------
--- Companion List Model
--------------------------------------------------------------------------------
local CompanionList = {}

Models.CompanionList = CompanionList

function CompanionList.new()
  return {
    pets = {},
    order = {},
    weights = {},
    total = 0
  }
end

function CompanionList.isEmpty(list)
  return not list or type(list.total) ~= "number" or list.total <= 0
end

function CompanionList.addPet(list, petGUID, weight)
  if not list then return false end
  list.pets = list.pets or {}
  list.order = list.order or {}
  list.weights = list.weights or {}
  list.total = list.total or 0

  if not list.pets[petGUID] then -- Add New Pet
    list.pets[petGUID] = true
    table.insert(list.order, petGUID)
    list.weights[petGUID] = tonumber(weight) or 1.0
    list.total = (list.total or 0) + 1
    return true
  else
    if weight ~= nil then -- Update existing pet Weight
      list.weights[petGUID] = tonumber(weight) or 1.0
    end
  end
  return false
end

function CompanionList.removePet(list, petGUID)
  if not (list and list.pets and list.pets[petGUID]) then
    return false
  end

  list.pets[petGUID] = nil
  if list.weights then
    list.weights[petGUID] = nil
  end

  for i, id in ipairs(list.order or {}) do
    if id == petGUID then
      table.remove(list.order, i)
      break
    end
  end
  list.total = math.max((list.total or 1) - 1, 0)
  return true
end

function CompanionList.hasPet(list, petGUID)
  return list and list.pets and petGUID and list.pets[petGUID] or false
end
