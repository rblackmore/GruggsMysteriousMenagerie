local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local companionModule = addOn:GetModule("CompanionModule")

local Data = addOn.Data
local Database = companionModule.Database

local MapUtils = addonTable.MapUtils
local Enums = addonTable.Enums
local CombatLockdownUtils = addonTable.CombatLockdownUtils
local Models = addonTable.Models
local CompanionList = Models.CompanionList

local SCOPES = Enums.SCOPES


--------------------------------------------------------------------------------
--- Local
--------------------------------------------------------------------------------

local function clearList(scope, ...)
  local dbp = Data.Companions.profile
  local dbc = Data.Companions.char
  local args = { ... }

  if scope == SCOPES.world then
    -- World scope: reset to empty list, don't nil it
    dbp.world = CompanionList:new()
  elseif scope == SCOPES.continent and args[1] then
    -- Continents: set to nil
    if dbp.continents then dbp.continents[args[1]] = nil end
  elseif scope == SCOPES.zone and args[1] and args[2] then
    -- Zones: set to nil
    if dbp.zones and dbp.zones[args[1]] then dbp.zones[args[1]][args[2]] = nil end
  elseif scope == SCOPES.outfit and args[1] then
    -- Outfits: set to nil
    if dbc.outfits then dbc.outfits[args[1]] = nil end
  end
end

local function ensureScope(scope, ...)
  local dbp = Data.Companions.profile

  if scope == SCOPES.world then
    dbp.world = CompanionList:new(dbp.world)
    return dbp.world
  end

  if scope == SCOPES.continent then
    local continentID = ...
    dbp.continents = dbp.continents or {}
    dbp.continents[continentID] = CompanionList:new(dbp.continents[continentID])
    return dbp.continents[continentID]
  end

  if scope == SCOPES.zone then
    local continentID, zoneID = ...
    dbp.zones = dbp.zones or {}
    dbp.zones[continentID] = dbp.zones[continentID] or {}
    dbp.zones[continentID][zoneID] = CompanionList:new(dbp.zones[continentID][zoneID])
    return dbp.zones[continentID][zoneID]
  end

  if scope == SCOPES.outfit then
    local outfitID = ...
    local dbc = Data.Companions.char
    dbc.outfits = dbc.outfits or {}
    dbc.outfits[outfitID] = CompanionList:new(dbc.outfits[outfitID])
    return dbc.outfits[outfitID]
  end
end

--------------------------------------------------------------------------------
--- Database Module API
--------------------------------------------------------------------------------
function Database:Init()
  Data["Companions"] = Data.AceDatabase:RegisterNamespace("Companions", {
    profile = {
      world = CompanionList:new(),
      continents = {},
      zones = {},
      fallback = {},
      cities = {},
      meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
    },
    char = {
      outfits = {},
      meta = { schemaVersion = 1, createdAt = time(), lastUpdated = time() },
    }
  })
end

function Database:AddPet(petGUID, scope, ...)
  local list = self:GetListForScope(scope, ...)

  if list then
    list:add(petGUID)
  end
end

function Database:RemovePet(petGUID, scope, ...)
  local list = self:GetListForScope(scope, ...)

  if list then
    list:remove(petGUID)
  end
end

function Database:AddOrRemovePet(petGUID, scope, ...)
  local list = self:GetListForScope(scope, ...)

  if list:hasPet(petGUID) then
    list:remove(petGUID)
  else
    list:add(petGUID)
  end
end

function Database:ClearList(scope, ...)
  clearList(scope, ...)
end

function Database:GetListForScope(scope, ...)
  local dbp = Data.Companions.profile
  local dbc = Data.Companions.char

  if scope == SCOPES.world then
    return dbp.world and CompanionList:new(dbp.world)
  end

  if scope == SCOPES.continent then
    local continentId = ...
    if continentId then
      return dbp.continents[continentId] and CompanionList:new(dbp.continents[continentId])
    end
  end

  if scope == SCOPES.zone then
    local continentId, zoneId = ...
    if continentId and zoneId then
      return dbp.zones[continentId] and
          dbp.zones[continentId][zoneId] and
          CompanionList:new(dbp.zones[continentId][zoneId])
    end
  end

  if scope == SCOPES.outfit then
    local outfitId = ...
    if outfitId then
      return dbc.outfits[outfitId] and CompanionList:new(dbc.outfits[outfitId])
    end
  end
end

function Database:EnsureScope(scope, ...)
  return CompanionList:new(ensureScope(scope, ...))
end

function Database:GetCurrentContextPetList()
  local outfitID = C_TransmogOutfitInfo.GetActiveOutfitID()
  local mapID = C_Map.GetBestMapForUnit("player")
  local _, continentID = MapUtils.GetContinentIDForMap(mapID)

  local outfitList = self:GetListForScope(SCOPES.outfit, outfitID)
  local continentList = self:GetListForScope(SCOPES.continent, continentID)
  local zoneList = self:GetListForScope(SCOPES.zone, continentID, mapID)
  local worldList = self:GetListForScope(SCOPES.world)

  return outfitList or continentList or zoneList or worldList
end

function Database:GetListForContextScope(scope, ensure)
  if scope == SCOPES.world then
    if ensure then self:EnsureScope(scope) end
    return Database:GetListForScope(scope)
  end

  if scope == SCOPES.continent then
    local success, continentId = MapUtils.GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    if ensure then self:EnsureScope(scope, continentId) end
    return Database:GetListForScope(scope, continentId)
  end
  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = MapUtils.GetContinentIDForMap(mapId)
    if ensure then self:EnsureScope(scope, continentId, mapId) end
    return Database:GetListForScope(scope, continentId, mapId)
  end
  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    if ensure then self:EnsureScope(scope, outfitId) end
    return Database:GetListForScope(scope, outfitId)
  end
end

function Database:BuildFallbackList()
  local dbp = Data.CompanionSettings.profile
  local useFavorites = dbp.UseFavoritesFallback

  ---@class GMM_Companion_List
  local list = CompanionList:new()
  local petGUIDs = C_PetJournal.GetOwnedPetIDs()


  for i = 1, #petGUIDs do
    local speciesID, _, _, _, _, _, isFavorite = C_PetJournal.GetPetInfoByPetID(petGUIDs[i])
    if speciesID then
      if not useFavorites or isFavorite then
        list:add(petGUIDs[i])
      end
    end
  end

  return list
end
