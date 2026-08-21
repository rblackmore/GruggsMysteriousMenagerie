local addonName, addonTable = ...
---@class AceAddon: AceConsole-3.0, AceEvent-3.0, AceTimer-3.0, GMM_Addon
local addOn = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@class AceAddon: AceTimer-3.0
local companionModule = addOn:GetModule("CompanionModule")

local Data = addOn.Data
local Database = companionModule.Database
local Utilities = addOn.Utilities
local Enums = Utilities.Enums

--------------------------------------------------------------------------------
--- Local
--------------------------------------------------------------------------------

local SCOPES = Enums.SCOPES

local function addPetToList(list, petGUID, weight)
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

local function removePetFromList(list, petGUID)
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

local function createEmptyList()
  return { pets = {}, order = {}, weights = {}, total = 0 }
end

local function clearList(scope, ...)
  local dbp = Data.Companions.profile
  local dbc = Data.Companions.char
  local args = { ... }

  if scope == SCOPES.world then
    -- World scope: reset to empty list, don't nil it
    dbp.world = createEmptyList()
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

local function ensureWorld()
  local dbp = Data.Companions.profile
  dbp.world = dbp.world or createEmptyList()
  return dbp.world
end

local function ensureContinent(continentID)
  local dbp = Data.Companions.profile
  dbp.continents = dbp.continents or {}
  local c = dbp.continents[continentID]
  if not c then
    c = createEmptyList()
    dbp.continents[continentID] = c
  end
  return c
end

local function ensureZone(continentID, zoneID)
  local dbp = Data.Companions.profile
  dbp.zones = dbp.zones or {}
  dbp.zones[continentID] = dbp.zones[continentID] or {}

  local z = dbp.zones[continentID][zoneID]
  if not z then
    z = createEmptyList()
    dbp.zones[continentID][zoneID] = z
  end
  return z
end

local function ensureOutfit(outfitID)
  local dbc = Data.Companions.char
  dbc.outfits = dbc.outfits or {}
  local o = dbc.outfits[outfitID]
  if not o then
    o = createEmptyList()
    dbc.outfits[outfitID] = o
  end
  return o
end

local function listHasPets(list)
  if not list then
    return false
  end
  if type(list.total) == "number" and list.total > 0 then
    return true
  end

  return list.order and #list.order > 0
end

local function getListFor(outfitID, mapID, continentID)
  local dbp = Data.Companions.profile
  local dbc = Data.Companions.char

  -- 1) Outfit
  if outfitID and dbc.outfits then
    local outfit = dbc.outfits[outfitID]
    if listHasPets(outfit) then
      return outfit
    end
  end

  -- 2) Zone
  if continentID and mapID and dbp.zones then
    local continent = dbp.zones[continentID]
    if continent then
      local zone = continent[mapID]
      if listHasPets(zone) then
        return zone
      end
    end
  end

  -- 3) Continent
  if continentID and dbp.continents then
    local continent = dbp.continents[continentID]
    if listHasPets(continent) then
      return continent
    end
  end

  -- 4 ) world
  if dbp.world and listHasPets(dbp.world) then
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
  local world = ensureWorld()
  local added = addPetToList(world, petGUID, weight)
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

  local continent = ensureContinent(continentID)
  local added = addPetToList(continent, petGUID, weight)
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

  local zone = ensureZone(continentID, zoneID)
  local added = addPetToList(zone, petGUID, weight)
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

  local outfit = ensureOutfit(outfitID)
  local added = addPetToList(outfit, petGUID, weight)
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

  local world = ensureWorld()
  local removed = removePetFromList(world, petGUID)
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

  local continent = ensureContinent(continentID)
  local removed = removePetFromList(continent, petGUID)
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

  local zone = ensureZone(continentID, zoneID)
  local removed = removePetFromList(zone, petGUID)
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

  local outfit = ensureOutfit(outfitID)
  local removed = removePetFromList(outfit, petGUID)
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
  local _, continentID = Utilities:GetContinentIDForMap(mapID)

  local list = getListFor(outfitID, mapID, continentID)

  return list
end

function Database:GetListForContextScope(scope)
  if scope == SCOPES.world then
    return Database:GetListForScope(scope)
  end
  if scope == SCOPES.continent then
    local success, continentId = Utilities:GetContinentIDForMap(C_Map.GetBestMapForUnit("player"))
    return Database:GetListForScope(scope, continentId)
  end
  if scope == SCOPES.zone then
    local mapId = C_Map.GetBestMapForUnit("player")
    local success, continentId = Utilities:GetContinentIDForMap(mapId)
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

  local list = createEmptyList()
  local petGUIDs = C_PetJournal.GetOwnedPetIDs()

  for i = 1, #petGUIDs do
    local speciesID, _, _, _, _, _, isFavorite = C_PetJournal.GetPetInfoByPetID(petGUIDs[i])
    if speciesID then
      if not useFavorites or isFavorite then
        addPetToList(list, petGUIDs[i])
      end
    end
  end

  return list
end
