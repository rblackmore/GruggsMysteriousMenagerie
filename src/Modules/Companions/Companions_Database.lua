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

local SCOPES = Enums.SCOPES

--------------------------------------------------------------------------------
--- Companion List Model
--------------------------------------------------------------------------------

local CompanionList = {}

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

--------------------------------------------------------------------------------
--- Local
--------------------------------------------------------------------------------

local function clearList(scope, ...)
  local dbp = Data.Companions.profile
  local dbc = Data.Companions.char
  local args = { ... }

  if scope == SCOPES.world then
    -- World scope: reset to empty list, don't nil it
    dbp.world = CompanionList.new()
  elseif scope == SCOPES.continent and args[1] then
    -- Continents: set to nil
    dbp.continents[args[1]] = nil
  elseif scope == SCOPES.zone and args[1] and args[2] then
    -- Zones: set to nil
    dbp.zones[args[1]][args[2]] = nil
  elseif scope == SCOPES.outfit and args[1] then
    -- Outfits: set to nil
    dbc.outfits[args[1]] = nil
  end
end

local function ensureScope(scope, ...)
  local dbp = Data.Companions.profile

  if scope == SCOPES.world then
    dbp.world = dbp.world or CompanionList.new()
    return dbp.world
  end

  if scope == SCOPES.continent then
    local continentID = ...
    dbp.continents = dbp.continents or {}
    dbp.continents[continentID] = dbp.continents[continentID] or CompanionList.new()
    return dbp.continents[continentID]
  end

  if scope == SCOPES.zone then
    local continentID, zoneID = ...
    dbp.zones = dbp.zones or {}
    dbp.zones[continentID] = dbp.zones[continentID] or {}
    dbp.zones[continentID][zoneID] = dbp.zones[continentID][zoneID] or CompanionList.new()
    return dbp.zones[continentID][zoneID]
  end

  if scope == SCOPES.outfit then
    local outfitID = ...
    local dbc = Data.Companions.char
    dbc.outfit = dbc.outfit or {}
    dbc.outfit[outfitID] = dbc.outfit[outfitID] or CompanionList.new()
    return dbc.outfit[outfitID]
  end
end

local function getListFor(outfitID, mapID, continentID)
  local dbp = Data.Companions.profile
  local dbc = Data.Companions.char

  -- 1) Outfit
  if outfitID and dbc.outfits then
    local outfit = dbc.outfits[outfitID]
    if not CompanionList.isEmpty(outfit) then
      return outfit
    end
  end

  -- 2) Zone
  if continentID and mapID and dbp.zones then
    local continent = dbp.zones[continentID]
    if continent then
      local zone = continent[mapID]
      if not CompanionList.isEmpty(zone) then
        return zone
      end
    end
  end

  -- 3) Continent
  if continentID and dbp.continents then
    local continent = dbp.continents[continentID]
    if not CompanionList.isEmpty(continent) then
      return continent
    end
  end

  -- 4 ) world
  if dbp.world and not CompanionList.isEmpty(dbp.world) then
    return dbp.world
  end

  -- 5) Fallback should be handled by Cache to avoid rebuilding each time on DB side
  return nil
end

--------------------------------------------------------------------------------
--- Database Module API
--------------------------------------------------------------------------------
function Database:Init()
  Data["Companions"] = Data.AceDatabase:RegisterNamespace("Companions", {
    profile = {
      world = { pets = {}, order = {}, weights = {}, total = 0 },
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

function Database:AddPetToWorld(petGUID, weight)
  if not petGUID then
    return false, "Missing petGUID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end
  local world = ensureScope(SCOPES.world)
  local added = CompanionList.addPet(world, petGUID, weight)
  return true, added and "Added" or "Updated"
end

function Database:AddPetToContinent(petGUID, continentID, weight)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not continentID then
    return false, "Missing continentID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local continent = ensureScope(SCOPES.continent, continentID)
  local added = CompanionList.addPet(continent, petGUID, weight)
  return true, added and "Added" or "Updated"
end

function Database:AddPetToZone(petGUID, continentID, zoneID, weight)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not continentID or not zoneID then
    return false, "Missing continentID or zoneID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local zone = ensureScope(SCOPES.zone, continentID, zoneID)
  local added = CompanionList.addPet(zone, petGUID, weight)
  return true, added and "Added" or "Updated"
end

function Database:AddPetToOutfit(petGUID, outfitID, weight)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not outfitID then
    return false, "Missing outfitID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local outfit = ensureScope(SCOPES.outfit, outfitID)
  local added = CompanionList.addPet(outfit, petGUID, weight)
  return true, added and "Added" or "Updated"
end

function Database:RemovePetFromWorld(petGUID)
  if not petGUID then
    return false, "Missing petGUID"
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local world = ensureScope(SCOPES.world)
  local removed = CompanionList.removePet(world, petGUID)
  return removed, removed and "Pet removed from Global List" or "Pet not found in global list"
end

function Database:RemovePetFromContinent(petGUID, continentID)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not continentID then
    return false, 'Missing continentID'
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local continent = ensureScope(SCOPES.continent, continentID)
  local removed = CompanionList.removePet(continent, petGUID)
  return removed, removed and "Pet removed from continent List" or "Pet not found in continent list"
end

function Database:RemovePetFromZone(petGUID, continentID, zoneID)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not continentID or not zoneID then
    return false, 'Missing continentID or zoneID'
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local zone = ensureScope(SCOPES.zone, continentID, zoneID)
  local removed = CompanionList.removePet(zone, petGUID)
  return removed, removed and "Pet removed from zone List" or "Pet not found in zone list"
end

function Database:RemovePetFromOutfit(petGUID, outfitID)
  if not petGUID then
    return false, "Missing petGUID"
  end

  if not outfitID then
    return false, 'Missing outfitID'
  end

  local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
  if not speciesID then
    return false, "Invalid petGUID"
  end

  local outfit = ensureScope(SCOPES.outfit, outfitID)
  local removed = CompanionList.removePet(outfit, petGUID)
  return removed, removed and "Pet removed from outfit List" or "Pet not found in outfit list"
end

function Database:ClearList(scope, ...)
  clearList(scope, ...)
end

function Database:GetListForScope(scope, ...)
  local dbp = Data.Companions.profile
  local dbc = Data.Companions.char

  local args = { ... }

  if scope == SCOPES.world then
    return dbp.world
  end

  if scope == SCOPES.continent then
    if args[1] then
      return dbp.continents[args[1]]
    end
  end

  if scope == SCOPES.zone then
    if args[1] and args[2] then
      return dbp.zones[args[1]][args[2]]
    end
  end

  if scope == SCOPES.outfit then
    if args[1] then
      return dbc.outfits[args[1]]
    end
  end
  return nil
end

function Database:GetCurrentContextPetList()
  local outfitID = C_TransmogOutfitInfo.GetActiveOutfitID()
  local mapID = C_Map.GetBestMapForUnit("player")
  local _, continentID = MapUtils.GetContinentIDForMap(mapID)

  local list = getListFor(outfitID, mapID, continentID)

  return list
end

function Database:GetListForContextScope(scope)
  if scope == SCOPES.world then
    return Database:GetListForScope(scope)
  end
  if scope == SCOPES.continent then
    local success, continentId = MapUtils.GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    return Database:GetListForScope(scope, continentId)
  end
  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = MapUtils.GetContinentIDForMap(mapId)
    return Database:GetListForScope(scope, continentId, mapId)
  end
  if scope == SCOPES.outfit then
    local outfitId = C_TransmogOutfitInfo.GetActiveOutfitID()
    return Database:GetListForScope(scope, outfitId)
  end
end

function Database:BuildFallbackList()
  local dbp = Data.Settings.profile
  local useFavorites = dbp.companions.UseFavoritesFallback

  local list = CompanionList.new()
  local petGUIDs = C_PetJournal.GetOwnedPetIDs()

  for i = 1, #petGUIDs do
    local speciesID, _, _, _, _, _, isFavorite = C_PetJournal.GetPetInfoByPetID(petGUIDs[i])
    if speciesID then
      if not useFavorites or isFavorite then
        CompanionList.addPet(list, petGUIDs[i])
      end
    end
  end

  return list
end
